#!/bin/bash
# Script that interacts with MPM (MATLAB Package Manager) to install MathWorks products.
# Each product specified should be separated with a space. Spaces in a name are separated with an underscore.

# This script doesn't support macOS. A Go program will be made to support all 3 operating systems.
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "$(tput setaf 1)macOS is unsupported. Exiting.$(tput sgr0)"
    exit 1
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo ""
else
    echo -e "\e[31mWARNING: Unrecognized operating system. This script may malfunction.\e[0m"
fi

prompt_download_directory() {
  echo "Enter the path to the directory where you would like MPM to download to. Press Enter to use /tmp."
  read -p "> " downloadDirectory

# Check if the user provided a file path, otherwise use "/tmp".
if [[ -z "$downloadDirectory" ]]; then
  downloadDirectory="/tmp"
fi

}

prompt_download_directory

# Check if the directory exists. If you type in a single word, it creates it in the current working directory.
while [[ ! -d "$downloadDirectory" ]]; do
  echo "Directory '$downloadDirectory' does not exist. Do you want to create it? (y/n)"
  read -p "> " createDownloadDirectory

  if [[ "$createDownloadDirectory" == "y" ]]; then
    if mkdir -p "$downloadDirectory"; then
      echo "Directory '$downloadDirectory' created."
    else
      prompt_download_directory
    fi
  else
    prompt_download_directory
  fi
done

cd "$downloadDirectory"

download_mpm(){
  wget https://www.mathworks.com/mpm/glnxa64/mpm
}

# Check if mpm already exists in this directory.
if [ -f "mpm" ]; then
    while true; do

      mpmExistsPrompt="MPM is already downloaded in this directory. Type 'y' to overwrite it with a newer copy or type 'n' to \
      use your existing copy (not recommended)."

      echo $mpmExistsPrompt
      read -p "> " choice

        case "$choice" in
            y|Y)
              echo "Overwriting existing MPM..."
              rm "mpm"
              download_mpm
              break
              ;;
            n|N)
              echo "Using existing MPM."
              existingMPM=true
              break
              ;;
            *)
              echo -e "\e[31mInvalid choice. Please enter 'y' or 'n'.\e[0m"
              ;;
        esac
    done
else
  download_mpm
fi

# If chmod fails, then ask about where you want to download MPM again.
chmod_output=$(chmod +x mpm 2>&1)

echo $chmod_output

# Any output from chmod is considered bad.
if [ -n "$chmod_output" ]; then
  prompt_download_directory
fi

# Pick your release number.
prompt_release_number() {
  echo "Which release would you like to install? (ex: R2023b). Press Enter to use the latest release."
  read -p "> " releaseNumber
}

# Check if it's valid/accepted.
validRelease=false

while [[ $validRelease == false ]]; do
    prompt_release_number

    if [[ -z "$releaseNumber" ]]; then
        releaseNumber="R2023b"
        validRelease=true
    elif [[ $releaseNumber != "R2017b" && \
          $releaseNumber != "R2018a" && \
          $releaseNumber != "R2018b" && \
          $releaseNumber != "R2019a" && \
          $releaseNumber != "R2019b" && \
          $releaseNumber != "R2020a" && \
          $releaseNumber != "R2020b" && \
          $releaseNumber != "R2021a" && \
          $releaseNumber != "R2021b" && \
          $releaseNumber != "R2022a" && \
          $releaseNumber != "R2022b" && \
          $releaseNumber != "R2023a" && \
          $releaseNumber != "R2023b" && \
          $releaseNumber != "R2024a" ]]; then
        echo -e "\e[31mInvalid release chosen. Please enter a release between R2017b-R2024a.\e[0m"
    else
        validRelease=true
    fi
done

prompt_product_list() {
  echo "Which products would you like to install? Press Enter to install all products."
  read -p "> " productList
}

prompt_product_list

# If you pressed Enter, get everything!
if [[ -z "$productList" ]]; then

  # Specify the products to add, starting from the bottom, and going up based on the release you picked.
  # Everything is one release off because the selected release has to be 1 less than the release being compared.
  declare -A newProductsToAdd=(
    ["R2023b"]="" # No new products in R2024a.
    ["R2023a"]="Simulink_Fault_Analyzer Polyspace_Test Simulink_Desktop_Real-Time"
    ["R2022b"]="MATLAB_Test C2000_Microcontroller_Blockset"
    ["R2022a"]="Medical_Imaging_Toolbox Simscape_Battery"
    ["R2021b"]="Wireless_Testbench Simulink_Real-Time Bluetooth_Toolbox DSP_HDL_Toolbox Requirements_Toolbox \
    Industrial_Communication_Toolbox"
    ["R2021a"]="Signal_Integrity_Toolbox RF_PCB_Toolbox"
    ["R2020b"]="Satellite_Communications_Toolbox DDS_Blockset"
    ["R2020a"]="UAV_Toolbox Radar_Toolbox Lidar_Toolbox Deep_Learning_HDL_Toolbox"
    ["R2019b"]="Simulink_Compiler Motor_Control_Blockset MATLAB_Web_App_Server Wireless_HDL_Toolbox"
    ["R2019a"]="ROS_Toolbox Simulink_PLC_Coder Navigation_Toolbox"
    ["R2018b"]="System_Composer SoC_Blockset SerDes_Toolbox Reinforcement_Learning_Toolbox Audio_Toolbox \
    Mixed-Signal_Blockset AUTOSAR_Blockset MATLAB_Parallel_Server Polyspace_Bug_Finder_Server \
    Polyspace_Code_Prover_Server Automated_Driving_Toolbox Computer_Vision_Toolbox"
    ["R2018a"]="Communications_Toolbox Simscape_Electrical Sensor_Fusion_and_Tracking_Toolbox Deep_Learning_Toolbox \
    5G_Toolbox WLAN_Toolbox LTE_Toolbox"
    ["R2017b"]="Predictive_Maintenance_Toolbox Vehicle_Network_Toolbox Vehicle_Dynamics_Blockset"      
    
    # These are the products available from every release from R2017b and onwards.
    ["R2017a"]="Aerospace_Blockset Aerospace_Toolbox Antenna_Toolbox Bioinformatics_Toolbox Control_System_Toolbox \
    Curve_Fitting_Toolbox DSP_System_Toolbox Database_Toolbox \
    Datafeed_Toolbox Econometrics_Toolbox Embedded_Coder Filter_Design_HDL_Coder Financial_Instruments_Toolbox \
    Financial_Toolbox Fixed-Point_Designer Fuzzy_Logic_Toolbox GPU_Coder Global_Optimization_Toolbox HDL_Coder HDL_Verifier \
    Image_Acquisition_Toolbox Image_Processing_Toolbox Instrument_Control_Toolbox MATLAB MATLAB_Coder \
    MATLAB_Compiler MATLAB_Compiler_SDK MATLAB_Production_Server MATLAB_Report_Generator Mapping_Toolbox \
    Model_Predictive_Control_Toolbox Optimization_Toolbox Parallel_Computing_Toolbox \
    Partial_Differential_Equation_Toolbox Phased_Array_System_Toolbox Polyspace_Bug_Finder Polyspace_Code_Prover \
    Powertrain_Blockset RF_Blockset RF_Toolbox Risk_Management_Toolbox \
    Robotics_System_Toolbox Robust_Control_Toolbox Signal_Processing_Toolbox SimBiology SimEvents Simscape Simscape_Driveline \
    Simscape_Fluids Simscape_Multibody Simulink Simulink_3D_Animation Simulink_Check Simulink_Coder \
    Simulink_Control_Design Simulink_Coverage Simulink_Design_Optimization Simulink_Design_Verifier \
    Simulink_Report_Generator Simulink_Test Stateflow Statistics_and_Machine_Learning_Toolbox \
    Symbolic_Math_Toolbox System_Identification_Toolbox Text_Analytics_Toolbox Vision_HDL_Toolbox Wavelet_Toolbox"
  )

  # Logic allowing us to start from the bottom of the list and work our way up.
  for release in "${!newProductsToAdd[@]}"; do
      if [[ $releaseNumber > $release ]]; then
          productList+=" ${newProductsToAdd[$release]}"
      fi
  done

  # We also need to add products that only existed in earlier releases/were named differently.
  # Everything is one release off because the selected release has to be 1 greater than the release being compared.
  declare -A oldProductsToAdd=(
    ["R2022a"]="Simulink_Requirements"
    ["R2021a"]="Fixed-Point_Designer Trading_Toolbox"
    ["R2020a"]="LTE_HDL_Toolbox"
    ["R2019a"]="Audio_System_Toolbox Automated_Driving_System_Toolbox Computer_Vision_System_Toolbox \
    MATLAB_Distributed_Computing_Server"
    ["R2018b"]="Communications_System_Toolbox LTE_System_Toolbox Neural_Network_Toolbox Simscape_Electronics \
    Simscape_Power_Systems WLAN_System_Toolbox"
  )
  
  # Logic allowing us to start from the top of the list and work our way down. This allows discontinued/renamed products to be installed.
  for release in "${!oldProductsToAdd[@]}"; do
      if [[ $releaseNumber < $release ]]; then
          productList+=" ${oldProductsToAdd[$release]}"
      fi
  done
fi

echo "Where would you like to install these products? Press Enter to install to /usr/local/MATLAB/$releaseNumber."
read -p "> " installationDirectory

# Check if the user provided an installation path, otherwise go to /usr/local/MATLAB/$releaseNumber.
if [[ -z "$installationDirectory" ]]; then
  installationDirectory="/usr/local/MATLAB/$releaseNumber"
fi

# Ask if you want to use a license file. If so, it needs to be exist and end with either .lic or .dat.
prompt_license_file() {
  while true; do
    echo "If you would like to activate now, please provide the path to your license file. Press Enter to add a license file yourself afterwards."
    read -p "> " originalLicenseFile

    if [ -z "$originalLicenseFile" ]; then
      break  # Exit the loop, leaving $originalLicenseFile blank.
    fi

    # Check if the file exists and has the correct file extension.
    if [ ! -f "$originalLicenseFile" ] || [[ ! "$originalLicenseFile" =~ \.(lic|dat)$ ]]; then
      echo -e "\e[31mInvalid license file specified. Please make sure the file exists and has either a .lic or .dat extension.\e[0m"
    else
      break  # Exit the loop, valid input provided.
    fi
  done
}

prompt_license_file

mpmOutput=$(./mpm install --release=$releaseNumber --destination=$installationDirectory --products $productList | tee /dev/tty)
#
# Delete MPM only if you downloaded during this installation. Otherwise, you probably still want it.
if [[ "$existingMPM" != true ]]; then
    rm "$downloadDirectory/mpm"
fi

# Check if "Installation complete" is present in the output of MPM.
if [[ $mpmOutput != *"Installation complete"* ]]; then
    echo -e "\e[31mInstallation failed. Please see the error above.\e[0m"
    exit 1
fi

# If you specified a license file, do the thing to put it in place.
if [[ -n "${originalLicenseFile// }" ]]; then
  cd $installationDirectory
  mkdir licenses
  cd licenses

  licenseFileName=$(basename "$originalLicenseFile")

  # Change the file extension to .lic if it's .dat. MATLAB doesn't like .dat.
  if [[ $licenseFileName == *.dat ]]; then    
    licenseFileName="${licenseFileName%.*}.lic"
  fi

  cp $originalLicenseFile $licenseFileName

fi
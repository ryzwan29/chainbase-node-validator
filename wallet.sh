#!/bin/bash

# Menampilkan menu pilihan untuk membuat atau mengimpor wallet
echo "Please choose an option:"
echo "1. Create a new Eigenlayer wallet"
echo "2. Import an existing Eigenlayer wallet"
read -p "Enter your choice (1 or 2): " choice

# Fungsi untuk membuat wallet baru
create_wallet() {
    echo -e "\033[1;32mCreating a new Eigenlayer wallet...\033[0m"
    
    # Perintah untuk membuat wallet baru dengan Eigenlayer
    eigenlayer operator keys create --key-type ecdsa opr
    
    # Meminta password untuk wallet
    echo -e "\033[1;32mEnter your password (Use a strong password like: ***123ABCabc123***)\033[0m"
    read -s -p "Password: " password
    echo
    
    # Informasi lebih lanjut
    echo -e "\033[1;32mSave your private key in a secure place!\033[0m"
    echo -e "\033[1;32mPress Ctrl+C to cancel if needed. Otherwise, press Enter to continue.\033[0m"
    
    # Menunggu konfirmasi pengguna untuk melanjutkan
    read -p "Press Enter to continue or Ctrl+C to exit..."
}

# Fungsi untuk mengimpor wallet lama
import_wallet() {
    echo -e "\033[1;32mImporting an existing Eigenlayer wallet...\033[0m"
    
    # Meminta private key untuk wallet yang akan diimpor
    read -p "Enter your private key: " private_key
    
    # Perintah untuk mengimpor wallet lama
    eigenlayer operator keys import --key-type ecdsa opr $private_key
    
    # Meminta password untuk wallet
    echo -e "\033[1;32mEnter your password (Use a strong password like: ***123ABCabc123***)\033[0m"
    read -s -p "Password: " password
    echo
    
    # Informasi lebih lanjut
    echo -e "\033[1;32mYour wallet has been imported successfully!\033[0m"
}

# Mengecek pilihan pengguna dan menjalankan fungsi yang sesuai
if [ "$choice" -eq 1 ]; then
    create_wallet
elif [ "$choice" -eq 2 ]; then
    import_wallet
else
    echo -e "\033[1;31mInvalid choice. Please select either 1 or 2.\033[0m"
fi

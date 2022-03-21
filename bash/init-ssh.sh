function_disable_ssh_password(){
    echo "disable ssh password login"
    echo "function_disable_ssh_password"
    if grep -q "^PasswordAuthentication" $ssh_config_file;then
      sed -i '/^PasswordAuthentication/s/yes/no/' $ssh_config_file
    else
      sed -i '$a PasswordAuthentication no' $ssh_config_file
    fi
}

function_disable_ssh_user_dns(){
    echo "disable ssh use dns"
    echo "function_disable_ssh_user_dns"
    if grep -q "^UseDNS" $ssh_config_file;then
      sed -i '/^UseDNS/s/yes/no/' $ssh_config_file
    else
      sed -i '$a UseDNS no' $ssh_config_file
    fi
}
#!/bin/bash
# user_name=u01
# group_name=g01
# user_pass=qwe123
ssh_config_file=/etc/ssh/sshd_config

arg_count=$#

while getopts ":u:p:g:k:h" optname
do
    case "$optname" in
      "u")
        echo "init username is: $OPTARG"
        user_name=$OPTARG
        ;;
      "p")
        echo "init user password is: $OPTARG"
        user_pass=$OPTARG
        ;;
      "g")
        echo "init group is : $OPTARG"
        group_name=$OPTARG
        ;;
      "k")
        echo "init public key is : $OPTARG"
        publick_key=$OPTARG
        ;;
      "h")
        echo "-h : This help message."
        echo "-a : New user username."
        echo "-p : New user password."
        echo "-g : New user group."
        echo "-k : New user public key."
        echo "Example: sh init-user.sh -a user01 -p 123123 -g group01 -k ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAA....."
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        exit
        ;;
      "?")
        echo "Unknown option $OPTARG"
        exit
        ;;
      *)
        echo "Unknown error while processing options"
        exit
        ;;
    esac
    #echo "option index is $OPTIND"
done

function_add_user(){
    echo "Creating user...."
    echo function_add_user
    file=`cat /etc/passwd |grep $user_name`
    if [ -z $file ]; then
        echo "The user is not exist."
        echo "Create new user $user_name with group $group_name and password $user_pass ."
        groupadd $group_name || {
          echo -e "[\033[31m ERROR \033[0m] Failed to create user group."
        }
        # mkdir -p /home/$user_name
        useradd $user_name -g $group_name -m -s /bin/bash || {
          echo -e "[\033[31m ERROR \033[0m] Failed to create user."
        }
        # chown -R $user_name:$group_name /home/$user_name
        echo $user_name:$user_pass|chpasswd || {
          echo -e "[\033[31m ERROR \033[0m] Failed to set passwd."
        }
    else
        echo "[\033[31m ERROR \033[0m] the user is exist."
        echo "end script."
        exit 1
    fi
}
function_add_sudo(){
    echo "Add new user sudo permission."
    echo function_add_sudo
    #yum install sudo 
    if [ -f /etc/sudoers ]; then
      echo "Add sudo to user: $user_name"
      echo "$user_name  ALL=(ALL:ALL) ALL" >> /etc/sudoers
    else
      echo "[\033[31m ERROR \033[0m] /etc/sudoers does not esxit, Please check it or install sudo."
      echo "end script"
      exit 1
    fi
}

function_add_key(){
    echo "Add public key to new user."
    echo function_add_key
    public_key_value=$publick_key
    ssh_dir="/home/$user_name/.ssh"
    auth_file=$ssh_dir/authorized_keys
    # create dir .ssh if no esxit
    if [ ! -d $ssh_dir ]; then
      echo "Creating ssh directory."
      mkdir $ssh_dir
    else
      echo "SSH dir esxit."
    fi
    echo $public_key_value >> $auth_file
    chown -R $user_name $ssh_dir
    chmod 600 $auth_file
}

function_disable_root_ssh(){
    echo "disable root login ssh"
    echo "function_disable_root_ssh"
    if grep -q "^PermitRootLogin" $ssh_config_file;then
      sed -i '/^PermitRootLogin/s/yes/no/' $ssh_config_file
    else
      sed -i '$a PermitRootLogin no' $ssh_config_file
    fi
}

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

function_input(){
    echo -e "\033[36m Please input username: \033[0m"
    read -r  input_username
    user_name=$input_username
    if [ ! -n $user_name ]; then
      echo -e "[\033[31m ERROR \033[0m] You must have a username. "
      exit 1
    fi
    echo -e "\033[36m Please input user password: \033[0m"
    read -r  input_password
    user_pass=$input_password
    if [ ! -n $user_pass ]; then
      echo -e "[\033[31m ERROR \033[0m] You must have a password. "
      exit 1
    fi
    echo -e "\033[36m Please input user group name: \033[0m"
    read -r  input_group
    group_name=$input_group
    if [ ! -n $group_name ]; then
      echo -e "[\033[31m ERROR \033[0m] You must have a group. "
      exit 1
    fi
    echo -e "\033[36m Please input your public key content: \033[0m"
    read -r input_public_key
    publick_key=$input_public_key
    if [ ! -n $publick_key ]; then
      echo -e "[\033[31m ERROR \033[0m] You must have a public key. "
      exit 1
    fi
}


main(){
  if [ $arg_count = 0 ]; then
    function_input
  fi
  # Check arg 
  if [ "$user_name" == "" ] || [ "$user_pass" == "" ] || [ "$group_name" == "" ] || [ "$publick_key" == "" ]; then
    echo -e "[\033[31m ERROR \033[0m]Please input all arg "
    exit 1
  fi
  function_add_user
  function_add_sudo
  function_add_key
  echo "User created."
  echo "##########################"
  echo 
  echo -e "\033[47;30m IMPORTANT!!!IMPORTANT!!!IMPORTANT!!!IMPORTANT!!! \033[0m"
  echo "##########################"
  read -r -p "The next steps will prohibit root login and password login. 
  Please test to confirm that your public key can log in normally, and the account has sudo privileges, 
  and then perform the following steps, have you confirmed?? [Y/n] " input
  case $input in
      [yY][eE][sS]|[yY])
          echo "Yes"
          function_disable_root_ssh
          function_disable_ssh_password
          function_disable_ssh_user_dns
          systemctl restart sshd
          exit
          ;;

      [nN][oO]|[nN])
          echo "You have chosen not execute next steps, the script will exit"
          exit
            ;;

      *)
          echo "Invalid input..."
          exit 1
          ;;
  esac
  echo -e "\033[32m Success \033[0m "
  echo Username: $user_name
  echo Password: $user_pass
  echo Groupname: $group_name

}


main | tee init-user.log
#echo $user_pass | passwd $user_name

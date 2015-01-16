#!/bin/bash
#
# Preconditions:
# 1) A Unix-like operating system such as Mac OSX or Linux
# 2) Acquia Dev Desktop or equivalent must be running
# 3) drush and git must be installed and exist in the environment path
# 5) An Apache vhost must be configured to include the deployment path
# 6) A line similar to '127.0.0.1 test.local' must exist in /etc/hosts
# 7) A MySQL database with proper user grants must exist
# 8) A valid deployment profile must exist in your home directory
#
# Example vhost config below (replace [me] with your username):
# <VirtualHost *>
#   ServerName test
#   DocumentRoot "/Users/[me]/Documents/Projects/test"
#   <Directory "/Users/[me]/Documents/Projects/test">
#     Options Indexes FollowSymLinks
#     AllowOverride All
#     Order allow,deny
#     Allow from all
#   </Directory>
# </VirtualHost>
#
if test $1; then
  prof=$1
  br=""
  if test $2; then
    br=$2
  fi
  in=""
  if test $3; then
    in=$3
  fi
  config=$HOME/$1.profile
  if [ ! -f "$config" ]; then
    echo "ERROR: $config is an invalid deployment profile"
    exit
  fi
  while read line; do
    for pair in $line; do
      set -- $(echo $pair | tr '=' ' ')
      if [ "$1" == "directory" ]; then
        directory=${line#"$1="}
      fi
      if [ "$1" == "dbname" ]; then
        dbname=${line#"$1="}
      fi
      if [ "$1" == "username" ]; then
        username=${line#"$1="}
      fi
      if [ "$1" == "password" ]; then
        password=${line#"$1="}
      fi
      if [ "$1" == "host" ]; then
        host=${line#"$1="}
      fi
      if [ "$1" == "port" ]; then
        port=${line#"$1="}
      fi
      if [ "$1" == "apache" ]; then
        apache=${line#"$1="}
      fi
      if [ "$1" == "repository" ]; then
        repository=${line#"$1="}
      fi
      if [ "$1" == "branch" ]; then
        if [ "$br" != "" ]; then
          branch=$br
        else
          branch=${line#"$1="}
        fi
      fi
      if [ "$1" == "modules" ]; then
        modules=${line#"$1="}
      fi
      if [ "$1" == "install" ]; then
        if [ "$in" != "" ]; then
          install=$in
        else
          install=${line#"$1="}
        fi
      fi
      if [ "$1" == "sitename" ]; then
        sitename=${line#"$1="}
      fi
      if [ "$1" == "admin" ]; then
        admin=${line#"$1="}
      fi
    done
  done < $config
  cd
  if [ -d "$directory" ]; then
    sudo rm -rf $directory/
  fi
  mkdir $directory
  cd $directory
  git clone $repository .
  if [ "$branch" != "master" ]; then
    git fetch && git checkout $branch
  fi
  if [ "$install" != "" ]; then
    if [ "$password" != "" ]; then
      dburl="mysql://$username:$password@$host:$port/$dbname"
    else
      dburl="mysql://$username@$host:$port/$dbname"
    fi
    drush site-install $install --account-pass="$admin" --db-url=$dburl --site-name="$sitename" -v -y
  else
    # Restore settings.php if no install profile
    settings=$HOME/$prof.settings.php
    if [ ! -f "$settings" ]; then
      echo "ERROR: $settings does not exist"
      exit
    fi
    cp -f $settings sites/default/settings.php
  fi
  if [ "$modules" != "" ]; then
    if [[ $modules == *"devel_themer"* ]]; then
      # The devel_themer contrib module depends on simplehtmldom
      # Download the latest version just in case newer versions of devel_themer require it
      cd sites/all/libraries
      if [ ! -d "simplehtmldom" ]; then
        mkdir simplehtmldom
      fi
      cd simplehtmldom
      if [ ! -f "simple_html_dom.php" ]; then
        curl -L -O http://downloads.sourceforge.net/project/simplehtmldom/simple_html_dom.php
        echo "Downloaded simple_html_dom.php to $(pwd)"
      fi
      cd $directory
      # Download the older version which, as of the date of this script, is required by devel_themer
      drush dl simplehtmldom-7.x-1.12
      drush en simplehtmldom -y
    fi
    drush dl $modules
    drush en $modules -y
    # drush en custom_developer_deployment -y
  fi
  # drush rsync @site.prod:%files/ @site.local:%files
  # Discover possible vhosts configurations
  domain=$prof.local
  root=$(drush status root --format=list)
  vhosts=/Applications/DevDesktop/apache/conf/vhosts.conf
  if [ -f $vhosts ]; then
    server=$(grep -1 $root $vhosts | head -1)
    domain=${server#"  ServerName "}
  else
    vhosts=/Applications/MAMP/conf/apache/vhosts.conf
    if [ -f $vhosts ]; then
      server=$(grep -1 $root $vhosts | head -1)
      domain=${server#"  ServerName "}
    fi
  fi
  echo "Browse to http://$domain:$apache"
else
  echo "Usage:"
  echo "drupal-deploy.sh <deploy profile> [feature branch] [install profile]"
  echo ""
  echo "Examples:"
  echo "1) drupal-deploy.sh deploy"
  echo "   This creates the environment as defined in ~/deploy.profile."
  echo ""
  echo "2) drupal-deploy.sh deploy my-feature-branch"
  echo "   This creates the environment as defined in ~/deploy.profile and overrides the branch with my-feature-branch."
  echo ""
  echo "3) drupal-deploy.sh deploy my-feature-branch custom"
  echo "   This creates the environment as defined in ~/deploy.profile and overrides the branch with my-feature-branch and install profile with custom."
  echo ""
  echo "4) drupal-deploy.sh deploy master custom"
  echo "   This creates the environment as defined in ~/deploy.profile and will not switch branches but overrides the install profile with custom."
  echo ""
  echo "5) drupal-deploy.sh deploy my-feature-branch \"\""
  echo "   This creates the environment as defined in ~/deploy.profile and overrides the branch with my-feature-branch and does not run an install profile."
  echo ""
  echo "6) drupal-deploy.sh deploy master \"\""
  echo "   This creates the environment as defined in ~/deploy.profile and will not switch branches or run an install profile."
  echo ""
  echo "The following deployment profiles are available:"
  ls -1 ~/*.profile
  echo ""
  echo "Execute drupal-deploy-config.sh to create a deployment profile."
fi

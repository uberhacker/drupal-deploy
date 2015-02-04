#!/bin/bash
#
# Please see README.txt before attempting to execute this script.
#

dir=$(pwd)
profdir=$HOME/drupal-deploy
if [ ! -d "$profdir" ]; then
  mkdir $profdir
fi
echo -n "Enter the directory for this install [$dir]: "; read directory
if [ -z "$directory" ]; then
  directory=$dir
fi
cd $directory
env=default
sites=$(find $directory/sites -type d -maxdepth 1)
for site in $sites; do
  settings=$site/settings.php
  if [ -f "$settings" ]; then
    env=$(basename $site)
  fi
done
if [ "$env" == "default" ]; then
  connection=$(drush sql-connect) || exit
else
  connection=$(drush -l $env sql-connect) || exit
fi
echo "The database credentials are from $directory/sites/$env/settings.php"
for pair in $connection; do
  set -- $(echo $pair | tr '=' ' ')
  if [ "$1" == "--user" ]; then
    user=$2
  fi
  if [ "$1" == "--password" ]; then
    pass=$2
  fi
  if [ "$1" == "--database" ]; then
    db=$2
  fi
  if [ "$1" == "--host" ]; then
    hst=$2
  fi
  if [ "$1" == "--port" ]; then
    prt=$2
  fi
done

echo -n "Enter your MySQL database name [$db]: "; read dbname
if [ -z "$dbname" ]; then
  dbname=$db
fi

echo -n "Enter your MySQL username [$user]: "; read username
if [ -z "$username" ]; then
  username=$user
fi

echo -n "Enter your MySQL password [$pass]: "; read password
if [ -z "$password" ]; then
  password=$pass
fi

echo -n "Enter your MySQL host [$hst]: "; read host
if [ -z "$host" ]; then
  host=$hst
fi

echo -n "Enter your MySQL port [$prt]: "; read port
if [ -z "$port" ]; then
  port=$prt
fi

# Discover possible Apache ports
listen=""
# DevDesktop Apache config
if [ -f "/Applications/DevDesktop/apache/conf/httpd.conf" ]; then
  listen=$(grep ^Listen /Applications/DevDesktop/apache/conf/httpd.conf)
fi
if [ "$listen" == "" ]; then
  # MAMP Apache config
  if [ -f "/Applications/MAMP/conf/apache/httpd.conf" ]; then
    listen=$(grep ^Listen /Applications/MAMP/conf/apache/httpd.conf)
  fi
fi
if [ "$listen" == "" ]; then
  # Older DevDesktop version port
  listen="Listen 8082"
fi
ap=${listen#"Listen "}
echo -n "Enter your Apache port [$ap]: "; read apache
if [ -z "$apache" ]; then
  apache=$ap
fi

repo=$(git config --get remote.origin.url)
echo -n "Which repository do you want to clone? [$repo]: "; read repository
if [ -z "$repository" ]; then
  repository=$repo
fi

echo -n "Which feature branch do you want to check out? [master]: "; read branch
if [ -z "$branch" ]; then
  branch=master
fi

modules=""
echo -n "Download and enable developer modules? [y]: "; read dm
if [ -z "$dm" ]; then
  dm=y
fi
if [ "$dm" == "Y" ]; then
  dm=y
fi
if [ "$dm" == "y" ]; then
  modules="coder xhprof hacked devel_themer examples"
fi

echo -n "Set up the environment with a Drupal install profile? [y]: "; read ip
if [ -z "$ip" ]; then
  ip=y
fi
if [ "$ip" == "Y" ]; then
  ip=y
fi

admin=""
install=""
sitename=""
multisite=""
if [ "$ip" == "y" ]; then
  # Prompt for install profile specific parameters
  echo -n "Enter the Drupal install profile [utexas]: "; read install
  if [ -z "$install" ]; then
    install=utexas
  fi

  echo -n "Enter the Drupal site name [$install]: "; read sitename
  if [ -z "$sitename" ]; then
    sitename=$install
  fi

  echo -n "Enter the admin account password [admin]: "; read admin
  if [ -z "$admin" ]; then
    admin=admin
  fi

  echo -n "Do you wish to add a multisite domain? [y]: "; read md
  if [ -z "$md" ]; then
    md=y
  fi
  if [ "$md" == "Y" ]; then
    md=y
  fi
  if [ "$md" == "y" ]; then
    echo -n "Enter your multisite domain: "; read multisite
  fi
else
  # No install profile requires that we restore settings.php
  if [ ! -f "$HOME/$profile.settings.php" ]; then
    cp -f sites/default/settings.php $profdir/$profile.settings.php
  fi
fi

profile=$(basename $directory)
profname=$profdir/$profile.profile
echo "directory=$directory" > $profname
echo "dbname=$dbname" >> $profname
echo "username=$username" >> $profname
echo "password=$password" >> $profname
echo "host=$host" >> $profname
echo "port=$port" >> $profname
echo "apache=$apache" >> $profname
echo "repository=$repository" >> $profname
echo "branch=$branch" >> $profname
echo "modules=$modules" >> $profname
echo "install=$install" >> $profname
echo "sitename=$sitename" >> $profname
echo "admin=$admin" >> $profname
echo "multisite=$multisite" >> $profname
echo "Deployment profile $profile stored in $profname"

echo -n "Deploy with the settings as configured above? [y]: "; read deploy
if [ -z "$deploy" ]; then
  deploy=y
fi
if [ "$deploy" == "Y" ]; then
  deploy=y
fi
if [ "$deploy" == "y" ]; then
  $(which drupal-deploy.sh) $profile
fi

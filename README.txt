Motivation:

Testing Drupal sites locally can take some time to set up manually.  This script is an attempt to automate the set up process so testing can be accelerated.  The main premise is to reuse an existing site configurations for testing different repositories and/or feature branches.

Preconditions:

1) A Unix-like operating system such as Mac OSX or Linux
2) Acquia Dev Desktop or equivalent AMP stack must be running
3) drush and git must be installed and exist in the environment path
5) An Apache vhost must be configured to include the deployment path
6) A localhost line must exist in /etc/hosts (eg. 127.0.0.1 deploy.local)
7) A MySQL database with proper user grants must exist

General Installation:

Repo: git clone https://github.com/uberhacker/drupal-deploy.git
Direct download: https://github.com/uberhacker/drupal-deploy/archive/master.zip

Copy drupal-deploy.sh and drupal-deploy-config.sh from the cloned repo or download directory to your ~/bin directory so they can be executed anywhere on the server.  If you don't have a ~/bin directory, create one: mkdir ~/bin.  Make sure the scripts are executable: chmod +x ~/bin/drupal-deploy*

Installation using Acquia Dev Desktop 2:

 1) Download and install Acquia Dev Desktop (see https://www.acquia.com/downloads)
 2) Launch terminal
 3) cd /path/to/project/directory
 4) git clone https://user@site/project/repo.git (eg. git clone https://username@bitbucket.org/my-project.git)
 5) Launch Acquia Dev Desktop
 6) Click the + sign in the lower left corner
 7) Choose Import local Drupal site...
 8) Click Change... and browse to /path/to/project/directory/my-project (where my-project is Drupal root of the cloned repo above)
 9) Under Use PHP:, select the appropriate PHP version
10) Verify the New database name: is correct
11) Click OK
12) Return to terminal
13) Follow the steps below in the Usage: section

Installation using MAMP:

Todo

Installation using XAMPP:

Todo

Usage:

$ cd /path/to/project/directory/my-project where my-project is the Drupal root
$ drupal-deploy-config.sh - Follow the prompts to configure a deployment profile
$ drupal-deploy.sh - See examples in the Usage: section

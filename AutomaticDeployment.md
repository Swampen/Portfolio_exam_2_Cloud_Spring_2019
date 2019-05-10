#### Automatic deployment

Step for step deployment.

For the deployment part off the assignement we decided to make a automatic deployment using **crontab** and **GIT** that we found verry usefull when testing the "students-grades.php" script. 



Make a public git repository (can be done with a secret repo but we decided to make it public for ease of access)



**Initial clone from GitHub:**

clone down the gitrepo from your preferd service on the "master webserver"

`git clone $GITPHPDEPLOYMENT /var/www/html;`



**Create script that pushes and pulls the code from GitHub:**

`webs=""`

`git pull`

`for web in $webs; `

`do`

`rsync -chavz --delete --exclude ".*" -e "ssh -i ~/.ssh/KEY.pem" /var/www/html 		      ubuntu@$web:/var/www/`

`done`



This scripts pulls down the latest version of the git repo from ur preferd service, then itterate over X numbers of web servers and pushes the newly updated gitrepo folder from the master web server. This is done by using rsync and is done for every webserver except the master web server its excecuted on.



**Nginx config setup:**

Since we use nginx for the web server we need to edit the config to display a new site if added.

Got to: `~/etc/nginx/sites-available/default`



Add your new website:

`root /var/www/html;`

`index index.php "add your script"."the extention of choise" test.php index.html students-grades.php index.htm index.nginx-debian.html;`



**Make crontab exceute every X minuets:**

`*/3 * * * * /bin/sh /home/ubuntu/"git pull script / rsync push script" `

The crontab script over tells the vm to excecute the script  /home/ubntu/"name" every 3 minuets.

So in short every 3 minuets we pull down the latest version from the git repo and pushes it out to the "slave" web servers.
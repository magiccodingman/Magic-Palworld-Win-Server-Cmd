# Magic-Palworld-Win-Server-Cmd
Alter the top variables at the top of the CMD script. This will proceed to setup a dedicated server for Palworld in the target directory with multiple luxuries.

1.) Target directory will have a dedicated server get installed.

2.) Will launch the exe if the saved file or other existing files don't yet exist and it'll wait for them to exist before proceeding. Therefore pre-generating all the required stuff.

3.) If you have multiple instances open at once of dedicated servers, it will not affect other existing instances, so you can safely run this without fearing it'll close out running servers.

4.) Will add an update bat file you can run that'll auto update the server

5.) Will add a "replicate default settings" bat which will replicate all the default settings you have to the secondary location it has to be replicated in as well every time. 

6.) Both the update and replicate bat files have variables in the create script that'll add those variables to the new startup bat I made. In which you can choose for the server when starting to automatically update and/or replicate the settings on each launch automatically. This way you can choose for the server to automatically perform these tasks as wanted

7.) Will edit the Engine.ini to add very helpful performance improvements. It'll do this with smart logic as well as to not remove settings you may have made or added and it won't duplicate the settings if you reran the script.

8.) Additionally with the new start bat file created for you, it'll translate the variables you set for the query and game port, player, and more. It'll also be critical this is the script you run as it properly does multiple tasks including utilizing your hardware to the fullest. Without the commands that is launched with the startup script, the server will run like poop. Set the variables at the top of the script as you wish them to be. It should be hopefully pretty self expanitory. Famous last words of a developer not documenting lol.

9.) The script is safe if you accidentally ran it on the same location multiple times, nor will it delete saves when rerun. The only thing it could mess up if you reran it on a folder you've been working on is if you reran it, it'd upgrade that path, it'd also reset the variable default settings to whatever you had on the script and it'd override engine.ini settings for variables being targetted. But it's minimal damage if you accidentally ran it over an existing server you didn't mean to run it on. Overall it's quite safe. Though it's not recommended. There's a reason there's other bat files for replicating the default settings or updating it. THat should be manual unless you wanted it on launch. This script truly is meant for a one time run preferably. 

10.) This sets your firewall rules for you. I've yet to test it on public servers for people to access. This does not alter your router obviously, just sets your windows to not be the issue. But it should do the TCP port properly without messing anything up for the Steam CMD query port you insert, and it'll add the UDP port to be allowed as well for you based on the port query you added. Again, this will not affect any of your existing ports, nor will it create duplicates, it's very wrapped and sound logic.

11.) This inserts the variables you chose for ports and players both to the startup script and the DefaultPalWorldSettings.ini for you. 

12.) If you run into any errors, it should tell you the issue. Like it'll throw an error if you didn't install steam cmd or if you didn't run as admin. But it should properly let you know if you didn't do something right.

13.) Will auto handle additional firewall defender popups that you otherwise would have dealt with. But it can only do so much. The first time you launch the server, make sure you check to allow both private and public. It's literally the only manual step to the entire process.

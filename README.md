Description
-----------
These scripts were written as a quick-and-dirty way for me to identify
duplicate image files across my harddrive(s) and copy them to a single
location, allowing the duplicates to be removed.

Only image files are checked (png, jpg, jpeg, and gif), but you can easily 
modify hash_files.rb to change or disable the file-extension check.

And finally, please use with caution. I highly suggest reading and understanding 
the source before executing anything. The scripts were not extensively tested.

Example
-------
The following two commands assume picture files are located at /home/USER/Backup_Pictures
and /Backups/Pictures. After running move_files.rb, all unique image files should be copied to
/home/USER/Pictures.

 	ruby hash_files.rb /home/USER/Backup_Pictures /Backups/Pictures /media/pix > pics.yaml
 	ruby move_files.rb /home/USER/Pictures pics.yaml
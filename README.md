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

You can run hash_files.rb with the --delete option to delete duplicates in place. You will
be prompted which file(s) to keep or provide a directory to move to.  The parent directory
of files you select will be "prioritized" and automatically selected any time there are other
duplicate files and one of the files is in a prioritized directory.

	ruby hash_files.rb --delete /home/USER/Pictures
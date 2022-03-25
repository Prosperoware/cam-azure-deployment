# Running the Azure shell script post deployment

The following notes will cover running the azuresecure.sh script to apply additional security changes located in the premium template deployment branch. 

https://github.com/Prosperoware/cam-azure-deployment/tree/masterpremium

Navigate to the Azure portal that contains the Resource Group the template linked above was deployed to. Press the icon near the top right of the window to open Cloud Shell, seen in the image below.

![2022-03-08_14-21-05](https://user-images.githubusercontent.com/73184475/160176734-ff4ab177-3577-4bb5-8a8d-8f386572d4ef.png)

If the Subscription doesn’t have a file share storage mounted users will be faced with the following dialog, click Show advanced settings.

![image](https://user-images.githubusercontent.com/73184475/160176966-842ad972-e7f5-4e18-a726-aa4fa3b8e816.png)

Ensure the correct region is selected to be able to create a file share within the storage account created from the template deployment. The file share can be named as desired. Click the Create storage button once finished adding the values.

![image](https://user-images.githubusercontent.com/73184475/160177064-7665a901-9516-4a9a-9b82-66aee5d2c23b.png)

Using the bash toolbar open the editor by clicking on the curly brackets. 

![image](https://user-images.githubusercontent.com/73184475/160177103-5e10113c-840f-4e4a-9dbd-733ec18c714b.png)

Copy the raw contents of the secureazure.sh script also located in the master premium branch initially linked above.

![image](https://user-images.githubusercontent.com/73184475/160177171-bb2da784-4614-4a54-a5cd-84fb9d18a1c5.png)

Paste this data into the editor dialog previously opened. Modify the rg value on line 2 to be the name of the Resource Group the deployment was conducted within.

![image](https://user-images.githubusercontent.com/73184475/160177235-e72480f7-595e-4d5d-a280-b43eae751891.png)

Press ‘ctrl + s’ on the keyboard to save this change. Save the new file as secureazure.sh. The file name can be changed as desired, but the extension should be .sh. 

![image](https://user-images.githubusercontent.com/73184475/160177295-0d4b30a9-0b86-45b0-a8fe-3671582ffa6a.png)

The users’ permissions will need to be modified to execute this script. In the bash type ‘chmod u+x [filename].sh’ making sure the correct file name is specified as saved previously. 

![image](https://user-images.githubusercontent.com/73184475/160177394-6c0369d0-2f11-467e-8881-b4c5d6676171.png)

After successfully updating the permissions the script can now be executed by typing ‘./[filename].sh’. Verify the deployment information gathered is correct before continuing. Finally, the script can be executed in steps by pressing any key as noted in the dialog output seen below. A message will be displayed with each step noting the changes being made and prompting the user to press any key to continue the process. 

![image](https://user-images.githubusercontent.com/73184475/160177470-dc779eec-c6b8-45fb-9636-294be5e32ac0.png)


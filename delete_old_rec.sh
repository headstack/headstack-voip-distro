#!/bin/bash

#Set the value of the variable. The value MUST BE A INTEGER!
#Example: if you specified the number 16, then the script will
#search for all recordings of conversations strictly older than 16 days.
NDATE=40

#Uncomment the MAILTO variable and set the administrator mail value
#to which the script will send a progress notification with statistics.
#MAILTO=mail@example.com

#Time of completion work
TOC=`date '+%Y.%m.%d %H:%M:%S'`

#Get IP for mail
IPADDR=`wget -qO- icanhazip.com`

#Destination directory for recursive search
NDIR=/var/spool/asterisk/monitor/

#Check old files for email
OLD_FILES=`find $NDIR -mtime +$NDATE`

#Check dir space before deleting for email
BEFORE=`du -sh /var/spool/asterisk/monitor/`

#Check if the directory exists
if [ -d /var/spool/asterisk/monitor/ ]; then

        echo -e "\nCheck if the monitor directory exists...\n\nThe monitor directory exists, continue...\n"

else

        echo -e "\nCheck if the monitor directory exists...\n\nThe monitor directory is not exists.\n\nExit with code 1.\n\nStop.\n"
        exit 1

fi

#Delete old file(s)
if [ "$OLD_FILES" != "" ]; then

        echo -e "We are looking for old conversation records with an age of more than $NDATE days...\n\nOld conversations found, delete them...\n"
        find $NDIR -mtime +$NDATE | xargs rm -f
        echo -e "Old conversations deleted done...\n"

else

        echo -e "We are looking for old conversation records with an age of more than $NDATE days...\n\nAs a result of the verification no old conversations were found.\n\nExit with code 1.\n\nStop.\n"
        exit 1

fi

#Check empty dir(s) for email
EMP_DIRS=`find $NDIR -type d -empty`

#Delete empty dir(s)
if [ "$EMP_DIRS" != "" ]; then

        echo -e "We are looking for empty directories...\n\nEmpty directories found, delete them...\n"
        find $NDIR -type d -empty | xargs rm -rf
        find $NDIR -type d -empty | xargs rm -rf
        echo -e "Empty directories deleted done...\n"

else

        echo -e "We are looking for empty directories...\n\nAs a result of the verification no empty directories were found.\n"

fi

#Check dir space after deleting for email
AFTER=`du -sh /var/spool/asterisk/monitor/`

#Check old files count for if operator
OLD_FILES_COUNT=`find $NDIR -mtime +$NDATE | wc -l`

#Check empty dir(s) count for if operator
EMP_DIRS_COUNT=`find $NDIR -type d -empty | wc -l`

#We will check the Postfix mail server before sending, if his down, then we will up them
PSX=$(systemctl status postfix.service | grep "Active:" | awk '{print $2}')

echo -e "Check if the Postfix mail server is running...\n"

if [ "$PSX" = "active" ]; then

        echo -e "Postfix is running.\n\nPass to the stage of preparation for dispatch...\n"

else

        echo -e "Postfix is not running. Trying up them...\n"
        systemctl enable postfix >/dev/null 2>&1
        systemctl start postfix >/dev/null 2>&1
        sleep 5
        PSX=$(systemctl status postfix.service | grep "Active:" | awk '{print $2}')

      if [ "$PSX" = "active" ]; then

        echo -e "Postfix is running.\n\nPass to the stage of preparation for dispatch...\n"

      else

        echo -e "Can not start the Postfix mail server. Email will not be sent.\n\nSee the systemctl log for more information.\n"

      fi

fi

#Chek delete status and send e-mail
if [[ "$OLD_FILES_COUNT" -eq 0 && "$EMP_DIRS_COUNT" -eq 0 ]]; then

        DSTAT="all old conversation records and empty directories have been deleted and we already have new conversations"
        echo -e "Chowning directories...\n"
        chown -R asterisk.asterisk $NDIR
        echo -e "Done.\n"
        echo -e "Check is done.\n\nPrepare information for sending to $MAILTO e-mail...\n\nSending a message for $MAILTO...\n"
        echo -e "Installed age of files measured in days: $NDATE\n\n\
        Conversation records space dir usage before deleting: $BEFORE\n\n\
        Old conversation records for deletion:\n$OLD_FILES\n\n\
        Empty conversation records dir(s) for deletion:\n$EMP_DIRS\n\n\
        Delete status: $DSTAT\n\n\
        Conversation records space dir usage after deleting: $AFTER\n\n\
        Timestamp of completion: $TOC\n" | mail -s "[HeadStack] Conversation Cleanup Alert from: $IPADDR" $MAILTO
        echo -e "Sending complete.\n\nFor more information about sending e-mail see /var/log/maillog\n"

elif [[ "$OLD_FILES_COUNT" -eq 0 && "$EMP_DIRS_COUNT" -ge 1 ]]; then

        echo -e "We have empty non-deleted directories o_O\n"
        echo -e "Trying to fix the situation...\n"
        find $NDIR -type d -empty | xargs rm -rf
        echo -e "And we give the user asterisk rights to the monitor directory...\n"
        chown -R asterisk.asterisk $NDIR
        echo -e "Fine, check again...\n"

      if [[ "$OLD_FILES_COUNT" -eq 0 && "$EMP_DIRS_COUNT" -gt 1 ]]; then

        DSTAT="WARNING!!! all old conversation records were deleted, but an error occurred while deleting empty directories. Check the script settings and directory: /var/spool/asterisk/monitor/"
        echo -e "Chowning directories...\n"
        chown -R asterisk.asterisk $NDIR
        echo -e "Done.\n"
        echo -e "There are problems, check the script and directory monitor..!\n\nPrepare information for sending to $MAILTO e-mail...\n\nSending a message for $MAILTO...\n"
        echo -e "Installed age of files measured in days: $NDATE\n\n\
        Conversation records space dir usage before deleting: $BEFORE\n\n\
        Old conversation records for deletion:\n$OLD_FILES\n\n\
        Empty conversation records dir(s) for deletion:\n$EMP_DIRS\n\n\
        Delete status: $DSTAT\n\n\
        Conversation records space dir usage after deleting: $AFTER\n\n\
        Timestamp of completion: $TOC\n" | mail -s "[HeadStack] Conversation Cleanup Alert from: $IPADDR" $MAILTO
        echo -e "Sending complete.\n\nFor more information about sending e-mail see /var/log/maillog\n"

      else

        DSTAT="all old conversation records and empty directories have been deleted and while no new conversation records have been found"
        echo -e "Chowning directories...\n"
        chown -R asterisk.asterisk $NDIR
        echo -e "Done.\n"
        echo -e "Check is done.\n\nPrepare information for sending to $MAILTO e-mail...\n\nSending a message for $MAILTO...\n"
        echo -e "Installed age of files measured in days: $NDATE\n\n\
        Conversation records space dir usage before deleting: $BEFORE\n\n\
        Old conversation records for deletion:\n$OLD_FILES\n\n\
        Empty conversation records dir(s) for deletion:\n$EMP_DIRS\n\n\
        Delete status: $DSTAT\n\n\
        Conversation records space dir usage after deleting: $AFTER\n\n\
        Timestamp of completion: $TOC\n" | mail -s "[HeadStack] Conversation Cleanup Alert from: $IPADDR" $MAILTO
        echo -e "Sending complete.\n\nFor more information about sending e-mail see /var/log/maillog\n"

      fi

elif [[ "$OLD_FILES_COUNT" -ge 1 && "$EMP_DIRS_COUNT" -ge 0 ]]; then

        DSTAT="ALARM!!! We have a problem! Old conversation records and empty directories have not been deleted! Сheck script settings and directory immediately: /var/spool/asterisk/monitor/"
        echo -e "Chowning directories...\n"
        chown -R asterisk.asterisk $NDIR
        echo -e "Done.\n"
        echo -e "We have a trouble. Nothing Deleted.\n\nСheck script settings and directory immediately: /var/spool/asterisk/monitor/\n\nPrepare information for sending to $MAILTO e-mail...\n\nSending a message for $MAILTO...\n"
        echo -e "Installed age of files measured in days: $NDATE\n\n\
        Conversation records space dir usage before deleting: $BEFORE\n\n\
        Old conversation records for deletion:\n$OLD_FILES\n\n\
        Empty conversation records dir(s) for deletion:\n$EMP_DIRS\n\n\
        Delete status: $DSTAT\n\n\
        Conversation records space dir usage after deleting: $AFTER\n\n\
        Timestamp of completion: $TOC\n" | mail -s "[HeadStack] Conversation Cleanup Alert from: $IPADDR" $MAILTO
        echo -e "Sending complete.\n\nFor more information about sending e-mail see /var/log/maillog\n"

fi

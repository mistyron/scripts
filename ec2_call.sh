# Currently, it returns 1 on error to shell
# This script only tries twice with 30 and 50 seconds delay respectively. 
# If the EC2 instance does not change state by this time window, it will generate error.
# For future improvements, error codes can be added for bad exits
CMD=$1
INSTANCE_ID="i-04ade121f7be717a9"
WAIT_TO_COLD_START_s=50
EC2_RUNNING=0
EC2_PENDING=1
EC2_STOPPING=2
EC2_STOPPED=3
EC2_NULL=4
check_status="(aws ec2 describe-instance-status --instance-ids $INSTANCE_ID | jq '.InstanceStatuses[0].InstanceState.Name')"
start_ec2="(aws ec2 start-instances --instance-ids $INSTANCE_ID | jq '.StartingInstances[0].CurrentState.Name')"
stop_ec2="(aws ec2 stop-instances --instance-ids $INSTANCE_ID | jq '.StoppingInstances[0].CurrentState.Name')"
function show_help() {
	echo -e "Usage:\n\t start\t \"use this to start instance\"\n\t stop\t \"use this to stop instance\"\n"
	echo -e "Thank you :)\n"
}
function check_ec2_start(){
	start_ec2="$(aws ec2 start-instances --instance-ids $INSTANCE_ID | jq '.StartingInstances[0].CurrentState.Name')"
}
function check_ec2_stop(){
	stop_ec2="$(aws ec2 stop-instances --instance-ids $INSTANCE_ID | jq '.StoppingInstances[0].CurrentState.Name')"
}

function check_ec2_status(){
	check_status="$(aws ec2 describe-instance-status --instance-ids $INSTANCE_ID | jq '.InstanceStatuses[0].InstanceState.Name')"
}
function good_exit_hook(){
	echo -e "\n\n\t\tThank you for using firmware ec2 script :)\n\n"
	exit 0
}
# function to parse ec2 return. ec2 command is arguement.
function check_ec2_return(){
	echo $1| grep -q "running"
	if [ $? -eq 0 ]; then
		echo "running detected"
		return $EC2_RUNNING
	fi
	echo $1| grep -q "pending"
	if [ $? -eq 0 ]; then
		echo "pending detected"
		return $EC2_PENDING
	fi
	echo $1| grep -q "stopping"
	if [ $? -eq 0 ]; then
		echo "stopping detected"
		return $EC2_STOPPING
	fi
	echo $1| grep -q "stopped"
	if [ $? -eq 0 ]; then
		echo "stopped detected"
		return $EC2_STOPPED
	fi
	echo $1| grep -q "null"
	if [ $? -eq 0 ]; then
		echo "null detected"
		return $EC2_NULL
	fi
	echo "Problem in detecting return! Please let the maintainer knows"
	exit 1
}
# start script
echo -e "\nInteract with firmware EC2 instance with ID $INSTANCE_ID \n"
if [[ -z "$CMD" ]]; then
	show_help
	exit 1
fi
if [ "$CMD" == "start" ] || [ "$CMD" == "stop" ]; then
	echo "Command accepted as $CMD"
	echo""
else
	echo "Command $CMD rejected!"
	echo""
	show_help
	exit 1
fi
if [ "$CMD" == "start" ]; then
	check_ec2_status
	echo "EC2 instance with ID $INSTANCE_ID is $check_status"
	check_ec2_return "$check_status" 
	_resp=$?
	if [ $_resp -eq $EC2_NULL ]; then
		echo "EC2 instance with ID $INSTANCE_ID is not running"
		echo "EC2 instance with ID $INSTANCE_ID is about to start"
		check_ec2_start 
		echo "EC2 instance with ID $INSTANCE_ID is $start_ec2"
		echo "Please wait for 30 seconds"
		sleep 30	
		check_ec2_start 
		check_ec2_return "$start_ec2"
		_resp=$?
		if [ $_resp -eq $EC2_PENDING ]; then
			echo "Please wait another $WAIT_TO_COLD_START_s seconds"
			sleep $WAIT_TO_COLD_START_s
			check_ec2_start
			check_ec2_return "$start_ec2"
			_resp=$?
			if [ $_resp -eq $EC2_RUNNING ]; then
				echo "EC2 instance with ID $INSTANCE_ID just started running"
				sleep 10
			else
				echo "Not possible to make instance up and running. Please let maintainer knows"
				exit 1
			fi
		elif [ $_resp -eq $EC2_RUNNING ]; then
			echo "EC2 instance with ID $INSTANCE_ID just started running"
			sleep 10
		else
			echo "Problem with changing the instance to up and running. Please let maintainer knows"
			exit 1
		fi
	elif [ $_resp -eq $EC2_RUNNING ]; then
		echo "EC2 instance with ID $INSTANCE_ID is already running"
		echo "EC2 instance with ID $INSTANCE_ID does not need re-run"
	else
		echo "Problem with detecting initial state of ec2 instance. Please let maintainer knows"
		exit 1
	fi
	ssh ec2
	echo -e "\n\n\n\t****Don't forget to turn off the ec2 if no one else is using the instance****\n"
	good_exit_hook
elif [ "$CMD" == "stop" ]; then
	check_ec2_status
	echo "EC2 instance with ID $INSTANCE_ID is $check_status"
	check_ec2_return "$check_status" 
	_resp=$?
	if [ $_resp -eq $EC2_NULL ]; then
		echo "EC2 instance with ID $INSTANCE_ID is already not running"
		echo "EC2 instance with ID $INSTANCE_ID does not need re-stop"
		good_exit_hook
	elif [ $_resp -eq $EC2_RUNNING ]; then
		echo "EC2 instance with ID $INSTANCE_ID is running"
		echo "EC2 instance with ID $INSTANCE_ID is about to stop"
		check_ec2_stop
		echo "EC2 instance with ID $INSTANCE_ID is $stop_ec2"
		echo "Please wait for 30 seconds"
		sleep 30	
		check_ec2_stop
		check_ec2_return "$stop_ec2"
		_resp=$?
		if [ $_resp -eq $EC2_PENDING ]; then
			echo "Please wait another $WAIT_TO_COLD_START_s seconds"
			sleep $WAIT_TO_COLD_START_s
			check_ec2_stop
			check_ec2_return "$stop_ec2"
			_resp=$?
			if [ $_resp -eq $EC2_STOPPING ]; then
				echo "EC2 instance with ID $INSTANCE_ID just stopped running"
				sleep 10
			elif [ $_resp -eq $EC2_STOPPED ]; then
				echo "EC2 instance with ID $INSTANCE_ID just stopped running"
				sleep 10
			else
				echo "Not possible to make instance stop running. Please let maintainer knows"
				exit 1
			fi
		elif [ $_resp -eq $EC2_STOPPING ]; then
			echo "EC2 instance with ID $INSTANCE_ID just stopped running"
			sleep 10
		elif [ $_resp -eq $EC2_STOPPED ]; then
			echo "EC2 instance with ID $INSTANCE_ID just stopped running"
			sleep 10
		else
			echo "Problem with changing the instance to sotp and not running. Please let maintainer knows"
			exit 1
		fi
		good_exit_hook
	else
		echo "Problem with detecting initial state of exit ec2 instance. Please let maintainer knows"
		exit 1
	fi
fi
echo "wrong place in script"
exit 1

#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use WebService::Prowl;

# Flush after every write
$| = 1;

my ($socket,$client_socket);
my ($peeraddress,$peerport);
my ($IPADDRESS,$PORT,$PROWLKEY);
our $check_time = time();
our (@connections,@newconnections);

######
# USER VARIABLES
######

$IPADDRESS = "IP ADDRESS GOES HERE";
$PORT = "PORT GOES HERE";
$PROWLKEY = "PROWL API KEY GOES HERE";

# Socket creation
$socket = new IO::Socket::INET (
    LocalHost => "$IPADDRESS",
    LocalPort => "$PORT",
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
    ) or die "Error in Socket Creation : $!\n";

print "Listening for connections\n\n";

while(1) # To infinity and beyond!
{
    my $current_time = time();
    if (($check_time + 300) < $current_time)
    {
        print "Checking for active receiving clients\n\n";
        &verifycon;
        $check_time = time();
    }

    my $client_socket = $socket->accept();
    my $buf = <$client_socket>;
    if ($buf)
    {
        # Variables to hold the client's IP address and port
        $peeraddress = $client_socket->peerhost();
        $peerport = $client_socket->peerport();

        print "Connection to: $peeraddress:$peerport established.\n";

        # Check to see what the client is sending.
        if ($buf eq "send\n")
        {
            # messagepack stands for message packet
            # Its value is assigned from the return value of &sendmessage
            my $messagepack = &sendmessage($client_socket);

            # Checks to see if any receiving clients are connected
            if (&verifycon == 1)
            {
                &receivemessage($messagepack);
            }
            else
            {
                my @prowlmessage = split (",,",$messagepack);
                &prowlsend(@prowlmessage[0],@prowlmessage[1],@prowlmessage[2]);
            }
        }
        elsif ($buf eq "receive\n")
        {
            # Add the socket to the array and call verifycon
            push(@connections,$client_socket);
            &verifycon;
        }
    }
}

sub sendmessage
{
    my $client_socket = $_[0];

    print "Send request from client $peeraddress:$peerport\n";

    # Send an approval message to the sending client
    my $data = "approved";
    #print "$client_socket\n";
    print $client_socket "$data\n";

    # Receive the username and message from the client
    my $received = <$client_socket>;
    chomp($received);

    print "Received: \"$received\"\n\n";

    # Return the message packet from the sending client
    return $received;
}

sub receivemessage
{
    # Store the message (passed as a parameter)
    my $message = "@_";

    # Checks to make sure a receiving client is connected
    if (&verifycon == 1)
    {
        foreach my $receiver (@connections)
        {
            # Adds "mess" to the csv packet to signify that the packet is a message
            my $data = "mess,,$message";

            # Send the message packet to the client
            print $receiver "$data\n";
        }
    }
    else
    {
        print "No receiving clients exist.  Something went wrong.\n\n";
    }
}

# TODO: Clean this subroutine up.  It works but good god it's a mess
sub verifycon
{
    # Convert to scalar to find array size
    my $connections = @connections;
    my $counter = 0;

    # Iterate through @connections based on size of the array
    # Couldn't use a foreach since I will need the array index
    while ($counter < $connections)
    {
        # Send a greeting to the receiving client
        my $receiver = $connections[$counter];
        my $data = "hello_client";
        print $receiver "$data\n";

        # Receive the clients reply
        my $reply = <$receiver>;

        # If a reply was not received, this variable should be empty
        if ($reply)
        {
            chomp($reply);

            if ($reply ne "hello_server")
            {
                # If in this case, something weird hapened
                delete $connections[$counter];
            }
            else
            {
                # This is the ideal case.  This means the receiving client is
                # here and responded appropriately.  Send that client info to
                # the new array
                push(@newconnections,$receiver);
            }
        }
        else
        {
            # If $reply was empty, the receiving client is no longer connected
            delete $connections[$counter];
        }

        # Increment the counter
        $counter += 1;
    }

    # The contents of @connections is now stale and needs to be emptied
    undef(@connections);

    # Copy the newly initialized array to @connections
    @connections = @newconnections;

    # Empty new array for later use
    undef(@newconnections);

    # If @connections is not empty, a receiving clients exists.  Return 1
    if (@connections)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub prowlsend {
    my(@smessage) = @_;
    my $ws = WebService::Prowl->new(apikey => $smessage[2]);
    $ws->verify || die $ws->error();
    $ws->add(application => "irssi",
        event => @smessage[0],
        description => @smessage[1],
        url => "")
}

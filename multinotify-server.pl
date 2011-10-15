use warnings;
use IO::Socket::INET;
use Thread;

# Flush after every write
$| = 1;

my ($socket,$client_socket);
my ($peeraddress,$peerport);

our $message_check = 0;
our @message_list;


# Socket creation
$socket = new IO::Socket::INET (
    LocalHost => 'IP ADDRESS IN HERE',
    LocalPort => 'PORT IN HERE',
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
    ) or die "Error in Socket Creation : $!\n";

print "Listening for connections\n\n";

while(1) # To infinity and beyond!
{
    $client_socket = $socket->accept();
    $buf = <$client_socket>;
    if ($buf)
    {
        # Variables to hold the client's IP address and port
        $peeraddress = $client_socket->peerhost();
        $peerport = $client_socket->peerport();
        print "Connection to: $peeraddress:$peerport established.\n\n";

        # Check to see what the client is sending.
        # If it's sending "send", call the &sendmessage subroutine.
        # Otherwise call the &recievemessage subroutine.
        if ($buf eq "send\n")
        {
            &sendmessage;

            # If $receiver has a defined value, a receiving client
            # is connected in which case we need to call &receivemessage
            # to send the new message onto the receiving client.
            if(defined($receiver))
            {
                $message_check = 1;
                &receivemessage;
            }
            else
            {
                # Send to Prowl... eventually
            }
        }
        else
        {
            # If the client did not send "send" to the socket, it is a
            # receiving client.  Set the $receiver variable and call the
            # &receivemessage subroutine.
            $receiver = $client_socket;
            new Thread \&receivemessage;
        }
    }
    # The client has closed the socket.
    else
    {
        # If $receiver is set, the receiving client is connected to the server.
        if(defined($receiver))
        {
            # Check to see if the disconnecting client is the receiving client.
            # If it is, undefine the $receiver variable.
            if($client_socket eq $receiver)
            {
                undef $receiver
            }
        }

        # Remove the client from $read_set and close it.
        print "Client disconnected.\n\n";
        close($client_socket);
    }
}

sub sendmessage
{
    print "Send request from client $peeraddress:$peerport\n";

    # Send an approval message to the sending client
    $data = "approved";
    print $client_socket "$data\n";

    # Receive the username from the client and store it in $username
    $username = <$client_socket>;
    print "Username: $username";
    push (@message_list, $username);

    # Send the value "un" to the client to verify that the username was received
    $data = "un\n";
    print $client_socket "$data\n";

    # Receive the message from the client and store it in $message
    $message = <$client_socket>;
    print "Message: $message\n";
    push (@message_list, $message);
}

sub receivemessage
{
    # If the variable $username is defined, a message has been sent
    if ($message_check == 1)
    {
        # Send the username to the client
        print $receiver "$message_list[0]";
        # If the server received "thanks" form the receiving client proceed to
        # send the message to the client
        if (<$receiver> eq "thanks\n")
        {
            print $receiver "$message_list[1]";
        }
        @message_list = ();
        # Undefine the $username variable
        $message_check = 0;
    }
}

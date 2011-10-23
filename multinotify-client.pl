#!/usr/bin/perl

######
# Multinotify Desktop Client
# nchowning, 2011 - nathanchowning@me.com
######

# Set the app name and load the socket module
use constant APP_NAME => 'multinotify-client';
use IO::Socket::INET;

######
# USER VARIABLES
######

my $IPADDRESS = "IP ADDRESS IN HERE";
my $PORT = "PORT IN HERE";
my $MAXLENGTH = 40; # Only used with libnotify

# Check to see which notification modules are installed
# If none are installed, die
my $notifier;
if (eval{ require Gtk2::Notify; })
{
    $notifier = 'libnotify';
}
elsif (eval{ require Cocoa::Growl; })
{
    $notifier = 'growl';
}
else
{
    print "!!!No notifier module installed!!!\n
        Multinotify currently has built-in support for libnotify (Gtk2::Notify) and Growl (Cocoa::Growl).\n";
    die;
}

# Flush
$| = 1;
my ($socket,$client_socket);

# Socket variable initialization
$socket = new IO::Socket::INET (
    PeerHost => "$IPADDRESS",
    PeerPort => "$PORT",
    Proto => 'tcp',
    ) or die "ERROR in Socket Creation : $!\n";

print "Connection Successful.\n";

$data = "receive";
print $socket "$data\n";

while(1)
{
    # Store the received data (from the server) in $received and split
    # it into @receivear
    $received = <$socket>;
    chomp($received);
    my @receivear = split(",,",$received);

    # Check to see what the server has sent
    if ($received eq "hello_client")
    {
        my $data = "hello_server";
        print $socket "$data\n";
    }
    elsif ($receivear[0] eq "mess")
    {
        print "$receivear[1]: $receivear[2]\n";
        notify($receivear[1], $receivear[2]);
    }
    else
    {
        sleep(1);
    }

    # Set this to 2 so it will only enter the last else case unless updated
    $receivedar[0] = 2;
}
$socket->close();

sub notify
{
    # Set the username & message that is passed to this function
    my($username, $message) = @_;

    if ($notifier eq 'libnotify')
    {
        $message = &formatmsg($message);

        # Create the notification
        my $notification = Gtk2::Notify->new($username, $message, 'irssi.png');

        # Show the notification
        $notification->show;
    }
    elsif ($notifier eq 'growl')
    {
        # Create growl notifier
        Cocoa::Growl::growl_register(
            app           => 'irssi',
            icon          => 'irssi.png',
            notifications => [qw(irssi)],
        );
        
        # Show growl notification
        Cocoa::Growl::growl_notify(
            name        => 'irssi',
            title       => "Message from: $username",
            description => "$message"
        );
    }
}

sub formatmsg
{
    my ($message,$MAXLENGTH) = @_;

    # Strip characters that break libnotify
    $message =~ s/</(less than)/g;
    $message =~ s/>/(greater than)/g;
    $message =~ s/&/(AND)/g;

    # Variables for use in the formatting loop
    my $newmsg = "";
    my $substart = 0;
    my $msgbrk;
    my $line = substr($message,$substart,$MAXLENGTH);
    my $linecount = 0;

    # If the first four characters are http, no need to enter the loop
    # Set the linecount to 5 so it skips the loop.
    if (substr($message,0,4) eq "http")
    {
        $newmsg = substr($message,0,$MAXLENGTH);
        $linecount = 5;
    }

    # Only enter the loop if the length is greater than MAXLENGTH (40 by
    # default, and it has printed fewer than 5 lines already
    while (length($line) >= $MAXLENGTH and $linecount < 5)
    {
        # Finds the last occurrence of whitespace on this line, sets the
        # next iteration's starting point, and generates the substring
        # of the line up to the last occurrence of white space.
        $msgbrk = rindex($line," ");
        $substart = $substart + $msgbrk + 1;
        $line = substr($line,0,$msgbrk);

        # If the newmsg variable is empty, this is the first line
        if ($newmsg eq "")
        {
            $newmsg = $line;
        }
        else
        {
            $newmsg = $newmsg . "\n" . $line;
        }

        # Create the next line for the next iteration and increment
        # the line counter by 1
        $line = substr($message,$substart,$MAXLENGTH);
        $linecount += 1;
    }

    # Check to see which condition caused the loop to exit and act
    if ($linecount == 5)
    {
        $newmsg = $newmsg . "\n...";
    }
    else
    {
        # Print the final line
        $newmsg = $newmsg . "\n" . substr($message,$substart,$MAXLENGTH);
    }

    # Send the newly formatted message back to the caller
    return $newmsg;
}

"""Multinotify Server

Usage:
  multinotify-server.py [--loglevel=<loglevel>] [--log=<filename>]
  multinotify-server.py <ipaddress> <port> [--loglevel=(info | debug | warning)] [--log=<filename>]
  multinotify-server.py (-h | --help)
  multinotify-server.py --version

Options:    
  -h --help                             Show this screen.
  --version                             Show version.
  --loglevel=(info | debug | warning)   Set logging verbosity
  --log=<filename>                      Set log file name

"""
from docopt import docopt
import logging
from twisted.internet.protocol import Factory
from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor

# Initialize arguments
arguments = docopt(__doc__, version='Multinotify Server 1.5')

def main():
    # Setup logging
    if (arguments["--log"]):
        logfile = arguments["--log"]
    else:
        logfile = "multinotify.log"
    FORMAT = "%(asctime)-15s %(levelname)s - %(message)s"
    logging.basicConfig(filename=logfile,level=logging.DEBUG,format=FORMAT)

    # Set the listen IP address and port
    if (arguments["<ipaddress>"] and arguments["<port>"]):
        listenIP = arguments["<ipaddress>"]
        listenPort = int(arguments["<port>"])
    else:
        listenIP = "127.0.0.1"
        listenPort = 5730

    # Fire up the server
    logForMe("info","Starting server")
    logForMe("info","Listening on " + listenIP + ":" + str(listenPort))
    reactor.listenTCP(listenPort, MultinotifyFactory(), interface=listenIP)
    reactor.run()
    logForMe("info","Stopping server")

def logForMe(severity,message):
    # There's a better way of doing this, I'll clean it up later
    # Set logging level
    if (arguments["--loglevel"] == "info"):
        maxLog = 2
    elif (arguments["--loglevel"] == "debug"):
        maxLog = 1
    else:
        # Warning log level
        maxLog = 0

    # Set message severity
    if (severity == "info" and maxLog > 1):
        logging.info(message)
    elif (severity == "debug" and maxLog > 0):
        logging.debug(message)
    elif (severity == "warning"):
        logging.warning(message)

class Multinotify(LineReceiver):

    def __init__(self, sendClients, getClients):
        # Dict reference of send & get clients
        self.sendClients = sendClients
        self.getClients = getClients

        # Current client's number
        self.clientNum = 0

        # Can be SEND or GET
        self.clientType = None

        # Set the initial state of the client
        self.state = "GETCLIENTTYPE"

    def connectionMade(self):
        logForMe("debug","Connection from peer: " + self.transport.getPeer().host)

    def connectionLost(self, reason):
        # If the user diconnects, remove them from the dict
        clientDict = self.returnClientDict(self.clientType)

        if (clientDict != None and clientDict.has_key(self.clientNum)):
            logForMe("debug","Disconnected peer: " + self.returnClientID() + "@" + self.transport.getPeer().host)
            del clientDict[self.clientNum]
        else:
            logForMe("debug","Uninitialized peer " + self.transport.getPeer().host + " has disconnected.")

    def lineReceived(self, line):
        # Ensure that clientType has been set
        if self.state == "GETCLIENTTYPE":
            self.handle_GETCLIENTTYPE(line)
        else:
            self.handle_CHAT(line)

    def handle_GETCLIENTTYPE(self, clientType):
        self.clientType = clientType

        # Get the correct client dictionary
        clientDict = self.returnClientDict(self.clientType)

        # Find an available client number
        while (clientDict.has_key(self.clientNum)):
            self.clientNum += 1

        # Initialize this client in the dictionary
        clientDict[self.clientNum] = self

        # Tell the client its number & client type
        self.sendLine("%s,%s" % (self.clientNum,self.clientType))

        # Change state of client
        self.state = "CHAT"

        # Logging
        logForMe("debug", self.transport.getPeer().host + " initialized as " + self.returnClientID())

    def handle_CHAT(self, message):
        # If the sending client is a SEND client and GET clients are connected
        if (self.clientType == "SEND" and len(self.getClients) > 0):
            # Debug printing
            logForMe("debug",self.returnClientID() + " sent message \"" + message + "\"")

            # Format the message
            preface = self.returnClientID() + ",,"
            message = preface + message

            # Iterate through getClients sending the message
            for clientNum, protocol in self.getClients.iteritems():
                protocol.sendLine(message)
        elif (len(self.getClients) == 0):
            logForMe("warning","Message suppressed from " + self.returnClientID() + ": " + message + " - No receiving clients currently connected.")
        elif (self.clientType != "SEND"):
            logForMe("warning","Message suppressed from " + self.returnClientID() + ": " + message + " - Not a sending client.")

    def returnClientDict(self, clientType):
        if (clientType == "SEND"):
            return self.sendClients
        elif (clientType == "GET"):
            return self.getClients

    def returnClientID(self):
        return str(self.clientType) + ":" + str(self.clientNum)

class MultinotifyFactory(Factory):

    def __init__(self):
        self.sendClients = {}
        self.getClients = {}

    def buildProtocol(self, addr):
        return Multinotify(self.sendClients, self.getClients)

if __name__ == '__main__':
    main()

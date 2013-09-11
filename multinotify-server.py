######
# Multinotify Server
# nchowning 2013, nathanchowning@me.com
#####

from twisted.internet.protocol import Factory
from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor

def main():
    listenIP = "127.0.0.1"
    listenPort = 5730
    reactor.listenTCP(listenPort, MultinotifyFactory(), interface=listenIP)
    reactor.run()

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
        print "Uninitialized client has connected..."

    def connectionLost(self, reason):
        # If the user diconnects, remove them from the dict
        clientDict = self.returnClientDict(self.clientType)

        if (clientDict != None and clientDict.has_key(self.clientNum)):
            print self.returnClientID() + " disconnected."
            del clientDict[self.clientNum]
        else:
            print "Uninitialized client has disconnected."

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

        # Debug printing
        print self.returnClientID() + " initialized"

    def handle_CHAT(self, message):
        # If the sending client is a SEND client and GET clients are connected
        if (self.clientType == "SEND" and len(self.getClients) > 0):
            # Debug printing
            print self.returnClientID() + " sent message \"" + message + "\""

            # Format message
            message = "<%s> %s" % (self.clientNum, message)

            # Iterate through getClients sending the message
            for clientNum, protocol in self.getClients.iteritems():
                protocol.sendLine(message)

    def returnClientDict(self, clientType):
        if (clientType == "SEND"):
            return self.sendClients
        elif (clientType == "GET"):
            return self.getClients

    def returnClientID(self):
        return str(self.clientType) + ":" + str(self.clientNum)

class MultinotifyFactory(Factory):

    def __init__(self):
        print "Server initialized"
        self.sendClients = {}
        self.getClients = {}

    def buildProtocol(self, addr):
        return Multinotify(self.sendClients, self.getClients)

if __name__ == '__main__':
    main()

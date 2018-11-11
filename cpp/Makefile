CXX=g++

DEPS = openwallet.h

%.o: %.cpp $(DEPS)
	$(CXX) -c -o $@ $<

openwallet: openwallet.o
	$(CXX) -o openwallet openwallet.o -lcryptopp

#!/bin/make -f

install: 
ifeq ($(DESTDIR),)
	@echo 'Skipping call, DESTDIR does not yet exist'
else
	echo "Moving HTX files into target structure"
	rsync -Cav usr etc $(DESTDIR)
	chmod -R 755 $(DESTDIR)/etc/htx
	chmod 755 $(DESTDIR)/usr/bin/*
	chmod 755 $(DESTDIR)/usr/share/htx
	chmod 755 $(DESTDIR)/usr/share/perl5/htx
	chmod 755 $(DESTDIR)/usr/share/perl5/htx/t
	chmod 644 $(DESTDIR)/usr/share/htx
	chmod 644 $(DESTDIR)/usr/share/perl5/htx
	chown -R root.root $(DESTDIR)/usr/bin
	chown -R root.root $(DESTDIR)/usr/share/htx
	chown -R root.root $(DESTDIR)/usr/share/perl5
endif


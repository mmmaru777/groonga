SUBDIRS = sysconfig

scripts = groonga

if REDHAT_PLATFORM
initdir = $(sysconfdir)/init.d
dist_init_SCRIPTS = $(scripts)
else
EXTRA_DIST = $(scripts)
endif

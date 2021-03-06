# IPE Makefile

# NOTE: Build parallelism can be controlled from the command line by setting the
#       MAKEJOBS variable, e.g.: MAKEJOBS=1 make zeus_intel_parallel

# Static / Unconditional / Default variables

###nm20151014 
DIRS          = main neutral flip eldyn plasma dummygptl driver ###NOgptl
###DIRS          = main neutral flip eldyn plasma driver  ###Yesgptl
GPTL_INCFLAGS = -I../dummygptl
GPTL_LDFLAGS  = -L../dummygptl -lgptl
PPP_FLAGS     = --Fmodule=module_decomp --Free --comment --HaloSize=10

TARGETS = clean                   \
          trillian_cray_parallel  \
          trillian_cray_serial    \
          trillian_intel_parallel \
          trillian_intel_serial   \
          trillian_pgi_parallel   \
          trillian_pgi_serial     \
          zeus_intel_parallel     \
          zeus_intel_serial       \
          zeus_lahey_serial       \
          theia_intel_parallel    \
          theia_intel_serial

# Dynamic / Conditional variables

EXE           = $(CURDIR)/../bin/ipe_$(MACHINE)_$(COMPILER)_$(PARALLELISM).exe
FFLAGS        = $(strip $(OPT_FLAGS) $(DEBUG_FLAGS) $(GPTL_INCFLAGS) $(GPTL_LDFLAGS))
INCDIR        = $(CURDIR)/../include
LIB           = $(CURDIR)/../lib/libipe.a
PARALLEL_MAKE = $(MAKE) -j $(MAKEJOBS)
PPP           = $(SMS)/bin/ppp
SMS_INCFLAGS  = -I$(SMS)/include
###nm20151014 SMS_LDFLAGS   = -L$(SMS)/lib -lsms
SMS_LDFLAGS   = -L$(SMS)/lib -lsms  $(GPTL_LDFLAGS)

ifndef DEBUG
  DEBUG = no
endif

# trillian stanza

ifeq ($(MACHINE),trillian)
  GPTL_USE_GPTL = no
ifndef MAKEJOBS
  MAKEJOBS      = 12
endif
  ifeq ($(GPTL_USE_GPTL),yes)
    $(error GPTL support currently unavailable on trillian)
  endif
  ifeq ($(COMPILER),cray)
    MODCMD    = $(shell ./modcmd trillian cray)
    FCP       = ftn
    FCS       = ftn
    OPT_FLAGS = -O3 -em -ef -eZ -ra -h fp0
    SMS       = /mnt/lustre/lus0/space/madden/SMS/legacy_r689/trillian-cray
    ifeq ($(DEBUG),yes)
      DEBUG_FLAGS = -g -O0 -em -ef -eZ -ra
    endif
  endif
  ifeq ($(COMPILER),intel)
    MODCMD    = $(shell ./modcmd trillian intel)
    FCP       = ftn
    FCS       = ftn
    OPT_FLAGS = -O3 -fp-model precise
    SMS       = /mnt/lustre/lus0/space/madden/SMS/legacy_r689/trillian-intel
    ifeq ($(DEBUG),yes)
      DEBUG_FLAGS = -g -O0 -ftz -traceback -check bounds -fpe0
    endif
  endif
  ifeq ($(COMPILER),pgi)
    MODCMD    = $(shell ./modcmd trillian pgi)
    FCP       = ftn
    FCS       = ftn
    OPT_FLAGS = -O2
    SMS       = /mnt/lustre/lus0/space/madden/SMS/legacy_r689/trillian-pgi
    ifeq ($(DEBUG),yes)
      DEBUG_FLAGS = -g -O0 -Mbounds
    endif
  endif
endif

# zeus stanza

ifeq ($(MACHINE),zeus)
  GPTL_USE_GPTL = yes
ifndef MAKEJOBS
  MAKEJOBS      = 16
endif
  ifeq ($(COMPILER),intel)
    MODCMD    = $(shell ./modcmd zeus intel)
    FCP       = mpif90
    FCS       = ifort
    OPT_FLAGS = -O3 -fp-model precise
    SMS       = /contrib/acs/SMS/legacy_r617/zeus-intel-mpt
    ifeq ($(DEBUG),yes)
      DEBUG_FLAGS = -g -O0 -ftz -traceback -check bounds -fpe0
    endif
    ifeq ($(PARALLELISM),parallel)
      ifeq ($(GPTL_USE_GPTL),yes)
        GPTL_INCFLAGS = -I/scratch1/portfolios/BMC/fim/GPTL/gptl-v5.0/intel_mpi/include
        GPTL_LDFLAGS  = -L/scratch1/portfolios/BMC/fim/GPTL/gptl-v5.0/intel_mpi/lib -lgptl
      endif
    endif
    ifeq ($(PARALLELISM),serial)
      ifeq ($(GPTL_USE_GPTL),yes)
        GPTL_INCFLAGS = -I/scratch1/portfolios/BMC/fim/GPTL/gptl-v5.0/intel_nompi/include
        GPTL_LDFLAGS  = -L/scratch1/portfolios/BMC/fim/GPTL/gptl-v5.0/intel_nompi/lib -lgptl
      endif
    endif
  endif
  ifeq ($(COMPILER),lahey)
    MODCMD = $(shell ./modcmd zeus lahey)
    FCP    = mpif90
    FCS    = lf95
    SMS    = /contrib/acs/SMS/legacy_r617/zeus-lahey-mpt
    ifeq ($(DEBUG),yes)
      DEBUG_FLAGS = --chk -g --trap --trace --info
    endif
  endif
endif

# theia stanza

ifeq ($(MACHINE),theia)
  GPTL_USE_GPTL = no
ifndef MAKEJOBS
#tmp20160315 4esmf  MAKEJOBS      = 16
  MAKEJOBS      = 1
endif
  ifeq ($(COMPILER),intel)
    MODCMD    = $(shell ./modcmd theia intel)
    FCP       = mpiifort
    FCS       = ifort
#tmp20160315 4esmf    OPT_FLAGS = -O3 -fp-model precise
    OPT_FLAGS = ###-O -fPIC -m64 -mcmodel=small -threads  -openmp  ###4esmf
    SMS       = /contrib/sms/legacy/SMSr825-intel
    ifeq ($(DEBUG),yes)
      DEBUG_FLAGS = -g -O0 -ftz -traceback -check bounds -fpe0
    endif
    ifeq ($(PARALLELISM),parallel)
      ifeq ($(GPTL_USE_GPTL),yes)
        GPTL_INCFLAGS = -I/contrib/gptl/gptl-v5.4.4_impi_noomp/include
        GPTL_LDFLAGS  = -L/contrib/gptl/gptl-v5.4.4_impi_noomp/lib -lgptl
      endif
    endif
    ifeq ($(PARALLELISM),serial)
      ifeq ($(GPTL_USE_GPTL),yes)
        $(error GPTL support currently unavailable on theia serial intel)
#        GPTL_INCFLAGS = -I/scratch1/portfolios/BMC/fim/GPTL/gptl-v5.0/intel_nompi/include
#        GPTL_LDFLAGS  = -L/scratch1/portfolios/BMC/fim/GPTL/gptl-v5.0/intel_nompi/lib -lgptl
      endif
    endif
  endif
endif

VARS =                                \
       DIRS="$(DIRS)"                 \
       EXE="$(EXE)"                   \
       FCP="$(FCP)"                   \
       FCS="$(FCS)"                   \
       FFLAGS="$(FFLAGS)"             \
       INCDIR="$(INCDIR)"             \
       LIB="$(LIB)"                   \
       MODCMD="$(MODCMD)"             \
       PARALLELISM="$(PARALLELISM)"   \
       PPP="$(PPP)"                   \
       PPP_FLAGS="$(PPP_FLAGS)"       \
       SMS_INCFLAGS="$(SMS_INCFLAGS)" \
       SMS_LDFLAGS="$(SMS_LDFLAGS)"

# Targets

.PHONY: $(TARGETS) all ipe

all:
	$(info Valid targets are:)
	$(foreach x,$(TARGETS),$(info - $(x)))
	$(error Invalid target specified)

trillian_cray_parallel:
	$(MAKE) ipe MACHINE=trillian COMPILER=cray PARALLELISM=parallel

trillian_cray_serial:
	$(MAKE) ipe MACHINE=trillian COMPILER=cray PARALLELISM=serial

trillian_intel_parallel:
	$(MAKE) ipe MACHINE=trillian COMPILER=intel PARALLELISM=parallel

trillian_intel_serial:
	$(MAKE) ipe MACHINE=trillian COMPILER=intel PARALLELISM=serial

trillian_pgi_parallel:
	$(MAKE) ipe MACHINE=trillian COMPILER=pgi PARALLELISM=parallel

trillian_pgi_serial:
	$(MAKE) ipe MACHINE=trillian COMPILER=pgi PARALLELISM=serial

zeus_intel_parallel:
	$(MAKE) ipe MACHINE=zeus COMPILER=intel PARALLELISM=parallel

zeus_intel_serial:
	$(MAKE) ipe MACHINE=zeus COMPILER=intel PARALLELISM=serial

zeus_lahey_serial:
	$(MAKE) ipe MACHINE=zeus COMPILER=lahey PARALLELISM=serial

theia_intel_parallel:
	$(MAKE) ipe MACHINE=theia COMPILER=intel PARALLELISM=parallel

theia_intel_serial:
	$(MAKE) ipe MACHINE=theia COMPILER=intel PARALLELISM=serial

ipe:
	$(if $(filter 0,$(MAKELEVEL)),$(call USAGE))
	$(foreach x,$(DIRS),$(PARALLEL_MAKE) -C $(x) $(VARS) &&) true

clean:
	$(foreach x,$(DIRS),$(MAKE) -C $(x) clean &&) true
	$(RM) $(LIB) $(INCDIR)/*

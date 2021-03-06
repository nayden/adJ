#!/bin/sh
# Generar distribución Aprendiendo de Jesús.
# Dominio público de acuerdo a la legislación colombiana. 
# http://www.pasosdejesus.org/dominio_publico_colombia.html
# 2007. vtamara@pasosdeJesus.org. 

inter=$1;
sp=$2;

if (test ! -f "ver.sh") then {
	echo "Falta archivo de configuración ver.sh";
	if (test "ver.sh.plantilla") then {
		echo "Copiando configuración por defecto de ver.sh.plantilla";
		cp ver.sh.plantilla ver.sh
		echo "Este archivo de comandos es controlado por ver.sh, por favor editelo y vuelva a ejecutar"
		exit 0;
	} fi;
} fi;
if (test "$inter" = "-c") then {
	. ./$sp
} else {
	. ./ver.sh
} fi;


mkdir -p ./tmp

dini=`pwd`;

function die {
	echo $1;
	exit 1;
}

function vardef {
	if (test "$2" = "") then {
		die "Falta variable $1";
	} fi;
}

vardef DESTDIR $DESTDIR
vardef RELEASEDIR $RELEASEDIR
vardef XSRCDIR ${XSRCDIR}
echo "Genera distribución de adJ" | tee -a /var/tmp/distrib-adJ.bitacora
date | tee -a /var/tmp/distrib-adJ.bitacora
echo "DESTDIR=$DESTDIR" | tee -a /var/tmp/distrib-adJ.bitacora
echo "RELEASEDIR=$RELEASEDIR" | tee -a /var/tmp/distrib-adJ.bitacora
echo "XSRCDIR=$XSRCDIR" | tee -a /var/tmp/distrib-adJ.bitacora

mkdir -p $DESTDIR/usr/share/mk

cdir=`pwd`
if (test ! -d /usr/src) then {
	echo "Se requieren fuentes de sistema base en /usr/src";
} fi;
if (test ! -d /usr/src/sys) then {
	echo "Se requieren fuentes del kernel en /usr/src/sys";
} fi;
if (test ! -d $XSRCDIR) then {
	echo "Se requieren fuentes de Xorg 4 en $XSRCDIR";
} fi;
if (test ! -d /usr/obj) then {
	die "Se requiere directorio para compilar sistema base y kernel: /usr/obj";
} fi;

narq=`uname -m`

ANONCVS="anoncvs@anoncvs1.ca.openbsd.org:/cvs"
ANONCVS="anoncvs@mirror.planetunix.net:/cvs"

echo " *> Actualizar fuentes de CVS" | tee -a /var/tmp/distrib-adJ.bitacora
if (test "$inter" = "-i") then {
	echo -n "(s/n)?"
	read sn
}
else {
	sn=$autoCvs;
} fi;
if (test "$sn" = "s") then {
	cd /usr/src
	if (test ! -f CVS/Root) then {
		for i in `find . -name CVS`; do 
			echo $i;
			echo "$ANONCVS" > $i/Root;
		done;
	} fi;
	cvs -z3 update -Pd -r$R
	cd /usr/src/sys
	if (test ! -f CVS/Root) then {
		for i in `find . -name CVS`; do 
			echo $i;
			echo "$ANONCVS" > $i/Root;
		done;
	} fi;
	cvs -z3 update -Pd -r$R
	cd $XSRCDIR
	if (test ! -f CVS/Root) then {
		for i in `find . -name CVS`; do 
			echo $i;
			echo "$ANONCVS" > $i/Root;
		done;
	} fi;
	cvs -z3 update -Pd -r$R
	cd /usr/ports/
	if (test ! -f CVS/Root) then {
		for i in `find . -name CVS`; do 
			echo $i;
			grep "mystuff" $i > /dev/null 2>&1
			if (test "$?" != "0") then {
				echo "$ANONCVS" > $i/Root;
			} fi;
		done;
	} fi;
	cvs -z3 update -Pd -r$R
} fi;

echo " *> Transformar y compilar kernel APRENDIENDODEJESUS" | tee -a /var/tmp/distrib-adJ.bitacora
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn;
}
else {
	sn=$autoCompKernel;
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;

	cd /usr/src/sys
	$dini/hdes/servicio-kernel.sh	
	# Esta en general se cambiaron comentarios a lo largo de todas
    # las fuentes.  Ver documentación en 
    # http://aprendiendo.pasosdejesus.org/?id=Renombrando+Daemon+por+Service

	# Para compilar vmstat
	sudo cp /usr/src/sys/uvm/uvm_extern.h /usr/include/uvm/

	cd /usr/src/sys/arch/$ARQ/conf
	sed -e "s/^#\(option.*NTFS.*\)/\1/g" GENERIC > APRENDIENDODEJESUS
	rm -rf /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS/*
	config APRENDIENDODEJESUS
	cd ../compile/APRENDIENDODEJESUS
	rm .depend
	make clean 
	make -j4
	cp /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS/bsd $dini/$V$VESP-$ARQ/bsd
	cd /usr/src/sys/arch/$ARQ/conf
	sed -e "s/GENERIC/APRENDIENDODEJESUS/g" GENERIC.MP > APRENDIENDODEJESUS.MP
	rm -rf /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS.MP/*
	config APRENDIENDODEJESUS.MP
	cd ../compile/APRENDIENDODEJESUS.MP
	rm .depend
	make clean 
	make -j4
	cp /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS.MP/bsd $dini/$V$VESP-$ARQ/bsd.mp

} fi;

echo " *> Instalar kernel recien compilado" | tee -a /var/tmp/distrib-adJ.bitacora
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoInsKernel
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;
	cd /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS.MP
	make install
	echo "Debe reiniciar sistema para iniciar kernel mp (si prefiere el que es para un procesador simple instalelo manualmente)..." | tee -a /var/tmp/distrib-adJ.bitacora
#/	exit 0;
} fi;


function compilabase 	{
	cd /usr/src/sbin/wsconsctl && if (test ! -f obj/keysym.h) then { make keysym.h; } fi && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.bin/compile_et && if (test ! -f obj/error_table.h) then { make error_table.h; } fi && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.bin/tic && if (test ! -f obj/termsort.c) then { make termsort.c; } fi && make  | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.bin/infocmp && if (test ! -f obj/termsort.c) then { make termsort.c; } fi && make  | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.bin/sudo/lib && if (test ! -f obj/gram.c) then { make gram.h; } fi && cd .. && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.bin/tset && if (test ! -f obj/termsort.c) then { make termsort.c; } fi && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.sbin/rpc.statd && if (test ! -f obj/sm_inter.h) then { make sm_inter.h; } fi && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.sbin/afs/usr.sbin/ydr && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/usr.sbin/afs/lib/libarla && if (test ! -f obj/fs.h) then { make fs.h; } fi && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/gnu/usr.bin/cc/libcpp && if (test ! -f obj/localedir.h) then { make localedir.h; } fi && make | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/lib/libiberty/ && make depend -f Makefile.bsd-wrapper depend && make -f Makefile.bsd-wrapper | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/gnu/usr.bin/cc/libobjc && make depend | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/gnu/lib/libiberty/ && make -f Makefile.bsd-wrapper config.status | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/kerberosV/usr.sbin/kadmin/ && make kadmin-commands.h | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/kerberosV/usr.sbin/ktutil/ && make ktutil-commands.h | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/kerberosV/lib/libasn1 && make rfc2459_asn1.h && make rfc2459_asn1-priv.h && make cms_asn1.h && make cms_asn1-priv.h && make krb5_asn1-priv.h && make  digest_asn1-priv.h | tee -a /var/tmp/distrib-adJ.bitacora
	#find /usr/obj -name ".depend" -exec rm {} ';'
	DT=$DESTDIR
	unset DESTDIR 
	echo "whoami 1" >> /var/tmp/distrib-adJ.bitacora
	whoami >> /var/tmp/distrib-adJ.bitacora 2>&1
	cd /usr/src && make -j4 | tee -a /var/tmp/distrib-adJ.bitacora
	echo "whoami 1" >> /var/tmp/distrib-adJ.bitacora
	whoami >> /var/tmp/distrib-adJ.bitacora 2>&1
	export DESTDIR=$DT;
}

echo " *> Actualizar zonas horarias" | tee -a /var/tmp/distrib-adJ.bitacora
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoActZonasHorarias
} fi;
if (test "$sn" = "s") then {
	mkdir -p /tmp/tz
	rm -rf /tmp/tz/*
	cd /tmp/tz
	ftp ftp://ftp.iana.org/tz/tzdata-latest.tar.gz
	mkdir datfiles
	cd datfiles
	tar xvfz ../tzdata-latest.tar.gz
	cp -rf * /usr/src/share/zoneinfo/datfiles/
} fi;	

echo " *> Transformar y compilar resto del sistema base" | tee -a /var/tmp/distrib-adJ.bitacora
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoCompBase
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq" | tee -a /var/tmp/distrib-adJ.bitacora 
		exit 1;
	} fi;


	echo -n "Eliminar /usr/obj ";
	if (test "$inter" = "-i") then {
		echo -n "(s/n)? "
		read sn
	} 
	else {
		sn=$autoElimCompBase
	} fi;
	if (test "$sn" = "s" ) then {
		echo "Uyy, Eliminando"; 
		rm -rf /usr/obj/*
	} fi;
	echo "Esta operacion modificar tanto las fuentes en /usr como archivos en /etc e /include del sistema donde se emplea para hacer posible la compilación;"
	rm -f ${DESTDIR}/usr/include/g++ 
	mkdir -p ${DESTDIR}/usr/include/g++
	#export CFLAGS=-I/usr/include/g++/${ARQ}-unknown-openbsd${V}/
	# Aplicando parches sobre las fuentes de OpenBSD sin cambios para
	# facilitar aportar  a OpenBSD con prioridad cambios que posiblemente
	# serán aceptados más facilmente
	(cd $dini/arboldes/usr/src; for i in *patch; do echo $i; if (test ! -f /usr/src/$i) then { sudo cp $i /usr/src; (cd /usr/src; echo "A mano"; sudo patch -p1 < $i;) } fi; done) |  tee -a  /var/tmp/distrib-adJ.bitacora

	echo "* Copiando archivos nuevos en /usr/src" | tee -a /var/tmp/distrib-adJ.bitacora
	(cd $dini/arboldes/usr/src ; for i in `find . -type f | grep -v CVS | grep -v .patch`; do  if (test ! -f /usr/src/$i) then { echo $i; n=`dirname $i`; sudo mkdir -p /usr/src/$n; sudo cp $i /usr/src/$i; } fi; done )
	echo "* Cambiando /etc " | tee -a /var/tmp/distrib-adJ.bitacora
	cd /etc
	$dini/arboldd/usr/local/adJ/servicio-etc.sh	
	echo "* Cambiando /usr/src/etc" | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/etc
	$dini/arboldd/usr/local/adJ/servicio-etc.sh	
	echo "* Cambios iniciales a /usr/src" | tee -a /var/tmp/distrib-adJ.bitacora
	cd /usr/src/
	$dini/hdes/servicio-base.sh	
	grep LOG_SERVICE  /usr/include/syslog.h > /dev/null 2>&1
	if (test "$?" != "0") then {
		cd /usr/src/sys
		$dini/hdes/servicio-kernel.sh	
	} fi;
	cd /usr/src && make obj
	echo "* Completo make obj" | tee -a /var/tmp/distrib-adJ.bitacora
	echo "whoami 2" >>  /var/tmp/distrib-adJ.bitacora
	whoami >> /var/tmp/distrib-adJ.bitacora 2>&1
	cd /usr/src/etc && env DESTDIR=/ make distrib-dirs
	echo "whoami 2" >> /var/tmp/distrib-adJ.bitacora
	whoami >> /var/tmp/distrib-adJ.bitacora 2>&1
	echo "* Completo make distrib-dirs" | tee -a /var/tmp/distrib-adJ.bitacora
	#cd /usr/src/etc && env DESTDIR=$DESTDIR make distrib-dirs
	# Algunos necesarios para que make lo logre
	cd /usr/src/include
	make includes
	compilabase
	echo "* Completo compilabase" | tee -a /var/tmp/distrib-adJ.bitacora
	echo "whoami 3" >> /var/tmp/distrib-adJ.bitacora
	whoami >> /var/tmp/distrib-adJ.bitacora 2>&1
	cd /usr/src && unset DESTDIR && nice make -j4 SUDO=sudo build | tee -a /var/tmp/distrib-adJ.bitacora
	echo "whoami 3" >> /var/tmp/distrib-adJ.bitacora
	whoami >> /var/tmp/distrib-adJ.bitacora 2>&1
	echo "* Completo make build" | tee -a /var/tmp/distrib-adJ.bitacora
} fi;

export DLENG=es

function verleng {
	a=$1;
	if (test "$a" = "") then {
		echo "Falta archivo como primer parámetro en verleng" | tee -a /var/tmp/distrib-adJ.bitacora
		exit 1;
	} fi;
	echo $a;
	grep "DLENG" $a > /dev/null 2> /dev/null
	if (test "$?" != "0") then {
		echo "Instalador en español no está bien configurado en fuentes" | tee -a /var/tmp/distrib-adJ.bitacora
		echo "Agregar:
SCRIPT  \${CURDIR}/upgrade-\${DLENG}.sh                   upgrade
SCRIPT  \${CURDIR}/install-\${DLENG}.sh                   install
SCRIPT  \${CURDIR}/install-\${DLENG}.sub                  install.sub"
		echo "en $a";
		cp $a $a.antestrad
		sed -e "s/upgrade.sh/upgrade-\${DLENG}.sh/g;s/install.sh/install-\${DLENG}.sh/g;s/\/install.sub/\/install-\${DLENG}.sub/g;s/\/install.md/\/install-\${DLENG}.md/g" $a.antestrad > $a
	} fi;
}



#
echo " *> Hacer una distribución en $DESTDIR y unos juegos de instalación en $RELEASEDIR" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoDist
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;


#	cd /usr/src/distrib/crunch && make obj depend \ && make all install
	echo -n " *> Eliminar $DESTDIR y $RELEASEDIR antes " | tee -a /var/tmp/distrib-adJ.bitacora;
	if (test "$inter" = "-i") then {
		echo -n "(s/n)? "
		read sn
	} 
	else {
		sn=$autoElimDist
	} fi;
	if (test "$sn" = "s") then {
		test -d ${DESTDIR}- && mv ${DESTDIR}- ${DESTDIR}d- && \
                   rm -rf ${DESTDIR}d- &
		test -d ${DESTDIR} && mv ${DESTDIR} ${DESTDIR}- 
	} fi;
	mkdir -p ${DESTDIR} ${RELEASEDIR}
	ed /usr/src/etc/Makefile << EOF
/^LOCALTIME=
s/Canada\/Mountain/America\/Bogota/g
w
q
EOF
	#compilabase
	echo "DESTDIR=$DESTDIR" | tee -a /var/tmp/distrib-adJ.bitacora;
	cd /usr/src/etc && DESTDIR=/destdir nice make release | tee -a /var/tmp/distrib-adJ.bitacora;
} fi;


echo " *> Recompilar e instalar X-Window con fuentes de $XSRCDIR" | tee -a /var/tmp/distrib-adJ.bitacora;

if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoX
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq" | tee -a /var/tmp/distrib-adJ.bitacora;
		exit 1;
	} fi;


	mkdir -p ${DESTDIR}/usr/include
	cp -rf /usr/include/* ${DESTDIR}/usr/include/
	mkdir -p ${DESTDIR}/usr/lib
	cp -rf /usr/lib/crt* ${DESTDIR}/usr/lib/
	if (test "$XSRCDIR" != "/usr/xenocara") then {
		ln -s $XSRCDIR /usr/xenocara;
	} fi;
	cd $XSRCDIR
	$dini/hdes/xenocaraadJ.sh	
	mkdir -p ${DESTDIR}/usr/X11R6/bin
	mkdir -p ${DESTDIR}/usr/X11R6/man/cat1
	export X11BASE=/usr/X11R6
	echo "** bootstrap" | tee -a /var/tmp/distrib-adJ.bitacora;
	make bootstrap
	if (test "$?" != "0") then {
		echo " *> bootstrap incompleto";
		exit $?;
	} fi;
	echo "** obj" | tee -a /var/tmp/distrib-adJ.bitacora;
	make obj
	if (test "$?" != "0") then {
		echo " *> obj incompleto";
		exit $?;
	} fi;
	#rm -rf /usr/xobj/*
	#mkdir -p /usr/xobj/app/fvwm/libs
	echo "** build" | tee -a /var/tmp/distrib-adJ.bitacora;
	find /usr/xenocara -name config.status | xargs rm -f
	# en 4.6 toco agregar a /usr/xenocara/kdrive/Makefile.bsd-wrapper:
	#clean:
	# mv  $(_SRCDIR)/config.status $(_SRCDIR)/config.status-copia
	mkdir -p ${DESTDIR}
	make -j4 build
	# Despues de este toco
	#cp /usr/xenocara/xserver/config.status-copia /usr/xenocara/xserver/config.status 
	#rm -rf /usr/xobj/*
	#mkdir -p /usr/xobj/app/fvwm/libs
	#echo "** build 2";
	#make build
	if (test "$?" != "0") then {
		echo " *> build incompleto";
		exit $?;
	} fi;
} fi;

echo " *> Distribución de X-Window en $DESTDIR y un juego de instalación en $RELEASEDIR  con fuentes de $XSRCDIR" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoXDist
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;


	echo -n " *> Eliminar $DESTDIR " | tee -a /var/tmp/distrib-adJ.bitacora;
	if (test "$inter" = "-i") then {
		echo -n "(s/n)? "
		read sn
	} 
	else {
		sn=$autoElimXDist
	} fi;
	if (test "$sn" = "s") then {
        	test -d ${DESTDIR}- && mv ${DESTDIR} ${DESTDIR}d- && \
        		rm -rf ${DESTDIR}d- &
        	test -d ${DESTDIR} && mv ${DESTDIR} ${DESTDIR}- &
	} fi;
        mkdir -p ${DESTDIR} ${RELEASEDIR}
	(cd $XSRCDIR; nice make release)

} fi;

echo " *> Preparar bsd.rd" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoBsdrd
} fi;
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;
	
	rm -f /usr/src/distrib/miniroot/install-es.sh
	ln -s $dini/tminiroot/install-es.sh /usr/src/distrib/miniroot/install-es.sh
	rm -f /usr/src/distrib/miniroot/install-es.sub
	ln -s $dini/tminiroot/install-es.sub /usr/src/distrib/miniroot/install-es.sub
	rm -f /usr/src/distrib/miniroot/upgrade-es.sh
	ln -s $dini/tminiroot/upgrade-es.sh /usr/src/distrib/miniroot/upgrade-es.sh
	rm -f /usr/src/distrib/amd64/common/install-es.md
	ln -s $dini/tminiroot/install-amd64-es.md /usr/src/distrib/amd64/common/install-es.md
	rm -f /usr/src/distrib/i386/common/install-es.md
	ln -s $dini/tminiroot/install-i386-es.md /usr/src/distrib/i386/common/install-es.md
	verleng /usr/src/distrib/miniroot/list 
	verleng /usr/src/distrib/amd64/common/list 
	verleng /usr/src/distrib/i386/common/list 

	cd /usr/src/distrib/special/libstubs
	make
	cd /usr/src/sys/arch/$ARQ/stand/
	make
	DESTDIR=/destdir make install
	cd /usr/src/distrib/$ARQ/ramdisk_cd
	DLENG=es RELEASEDIR=${RELEASEDIR} make
	cp obj/bsd.rd ${RELEASEDIR}
	cp obj/bsd.rd $dini/$V$VESP-$ARQ
} fi;

cd $cdir
echo " *> Copiar juegos de instalación de sistema base y X-Window de $RELEASEDIR a $dini/$V$VESP-$ARQ?" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoJuegosInstalacion
} fi;

if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;


	cp /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS/bsd ${RELEASEDIR}/bsd
	cp /usr/src/sys/arch/$ARQ/compile/APRENDIENDODEJESUS.MP/bsd ${RELEASEDIR}/bsd.mp
	cd /usr/src/distrib/sets && sh checkflist
	cp $RELEASEDIR/* $dini/$V$VESP-$ARQ
	rm -f $dini/$V$VESP-$ARQ/{MD5,CKSUM,index.txt,cd??.iso,}
} fi;

echo " *> Generar paquetes de la distribución AprendiendoDeJesús en $dini/$V$VESP-$ARQ/paquetes " | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn=$autoPaquetes
} fi;


paraexc="";
function paquete {
	nom=$1;
	cat=$2;
	dest=$3;
	copiar=$4;
	subd=$5;
	if (test "$dest" = "") then {
		dest=paquetes;
	} fi;
	if (test "$nom" = "") then {
		echo "En llamado a funcion paquete falta nombre del paquete";
		exit 1;
	} fi;
	if (test "$cat" = "") then {
		echo "En llamado a funcion paquete falta categoria del paquete";
		exit 1;
	} fi;
	mys="mystuff";
	if (test ! -d "/usr/ports/$mys/$cat/$nom/$subd/") then {
		mys="";
	} fi;
	if (test ! -d "/usr/ports/$mys/$cat/$nom/$subd/") then {
		echo "No es directorio /usr/ports/$mys/$cat/$nom/$subd/";
		exit 1;
	} fi;
	echo "*> Creando paquete $nom:$cat" | tee -a /var/tmp/distrib-adJ.bitacora;
	(cd /usr/ports/$mys/$cat/$nom/$subd/ ; make package)
	if (test "$copiar" = "") then {
		echo "*> Copiando /usr/ports/packages/$ARQ/all/$nom-*.tgz" | tee -a /var/tmp/distrib-adJ.bitacora
		cmd="cp /usr/ports/packages/$ARQ/all/$nom-[0-9][0-9a-z.]*.tgz $dini/$V$VESP-$ARQ/$dest/";
		echo "cmd=$cmd";
		eval "$cmd";
		if (test "$paraexc" != "") then {
			paraexc="$paraexc $nom-*"
		} else {
			paraexc="$nom-*"
		} fi;
	} else {
		for i in $copiar; do
			cmd="cp /usr/ports/packages/$ARQ/all/$i-[0-9][0-9a-z.]*.tgz $dini/$V$VESP-$ARQ/$dest/"
			echo $cmd;
			eval $cmd
			if (test "$paraexc" != "") then {
				paraexc="$paraexc $i-*"
			} else {
				paraexc="$i-*"
			} fi;
		done;
	} fi;
}

echo $sn
if (test "$sn" = "s") then {
	if (test "$ARQ" != "$narq") then {
		echo "Esta operación requiere que ARQ en ver.sh sea $narq";
		exit 1;
	} fi;


	if (test ! -d "/usr/ports/mystuff") then {
		mkdir -p /usr/ports
		ln -s $dini/arboldes/usr/ports/mystuff /usr/ports/mystuff
	} fi;
	rm tmp/disponibles*
	paquete dialog misc
	# paquete php lang paquetes "php php-fpm php-gd php-mcrypt php-pdo_pgsql" 5.5  Tocó dejar 5.3 por pear -> SIVeL 1.2
	paquete ruby lang paquetes "ruby ruby20-ri_docs" 2.0

        # paquete pear www paquetes "pear pear-utils"  Toco quedarse en PHP 5.3 para SIVeL 1.2
	paquete pear www 
	paquete pear-Auth security
	#paquete pear-DB databases
	paquete pear-DB-DataObject databases
	paquete pear-DB-DataObject-FormBuilder www
	paquete pear-HTML-Common www
 	paquete pear-HTML-CSS www
 	paquete pear-Validate devel
 	#paquete pear-HTML-QuickForm www
 	paquete pear-HTML-QuickForm-Controller www
 	paquete pear-HTML-Javascript www
 	paquete pear-HTML-Menu www
 	paquete pear-HTML-Table www
 	
    	paquete ruby-apacheconf_parser devel paquetes "ruby19-apacheconf-parser"
    	paquete ruby-apache2nginx devel paquetes "ruby19-apache2nginx"

	paquete evangelios_dp books
	paquete sword textproc 
	paquete xiphos textproc 

	paquete realboy emulators

	paquete basico_OpenBSD books
	paquete usuario_OpenBSD books
	paquete servidor_OpenBSD books
	paquete AnimalesI education
	paquete AprestamientoI education
	paquete PlantasCursiva education
	paquete NombresCursiva education
	paquete TiposLectoEscritura fonts
	paquete asigna education
	paquete markup textproc 
	paquete repasa education
	paquete sigue education

	paquete sivel databases sivel sivel 1.1
	paquete sivel databases sivel sivel 1.2

	paquete fbdesk x11
	paquete xfe x11
        #paquete sqlite3 databases
	#paquete nspr devel paquetes "nspr"
        #paquete nss security 
        #paquete cairo graphics
        #paquete mozilla-firefox www 
        #paquete firefox-i18n www paquetes "firefox-i18n-es-AR"
#        paquete evince graphics
        paquete postgresql databases paquetes "postgresql-server postgresql-client postgresql-contrib"
	rm $dini/$V$VESP-$ARQ/$dest/php5-gd-*-no_x11.tgz

} fi;	

echo " *> Copiar otros paquetes de repositorio de OpenBSD" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn="$autoMasPaquetes"
} fi;


cd $dini
echo "$paraexc" | tr " " "\n" | grep -v "^[ \t]*$" | sed -e "s/^/ /g" > tmp/excluye.txt
cmd="echo \$excluye | tr \" \" \"\\n\" | sed -e \"s/^/ /g\" >> tmp/excluye.txt"
eval "$cmd"
if (test "$sn" = "s") then {
	mkdir -p $V$VESP-$ARQ/paquetes
	cp -rf arboldvd/* $V$VESP-$ARQ/
	find $V$VESP-$ARQ/ -name CVS | xargs rm -rf

	arcdis="tmp/disponibles.txt";
	arcdis2="tmp/disponibles2.txt";

	pftp=`echo $PKG_PATH | sed -e "s/^ftp:.*/ftp/g;s/^http:.*/ftp/g"`;
	echo pftp $pftp

	if (test ! -f "$arcdis") then {
		echo "Obteniendo lista de paquetes disponibles de $PKG_PATH" | tee -a /var/tmp/distrib-adJ.bitacora;
		if (test "$pftp" = "ftp") then {
			cmd="echo \"ls\" | ftp $PKG_PATH > /tmp/actu2-l"
		} else {
			cmd="ls $PKG_PATH > /tmp/actu2-l";
		} fi;
		echo $cmd; eval $cmd;
		cmd="grep -a \".tgz\" /tmp/actu2-l | sort "
		if (test "$autoMasPaquetesInv" = "s") then {
			cmd="$cmd -r ";
		} fi;
		cmd="$cmd > /tmp/actu2-g"
		echo $cmd; eval $cmd;
		cmd="sed -e \"s/.*\( [A-Za-z0-9.-][_A-Za-z0-9.@+-]*.tgz\).*/\1 /g\" /tmp/actu2-g > /tmp/actu2-s"
		echo $cmd; eval $cmd;
		if (test "$excluye" != "") then {
			cmd="grep -v -f tmp/excluye.txt /tmp/actu2-s > $arcdis";
		} else {
			cmd="cp /tmp/actu2-s $arcdis";
		} fi;
		echo $cmd; eval $cmd;

		if (test ! -s "$arcdis") then {
			echo "No pudo obtenerse lista (asegurese de terminar ruta con /)";
			exit 1;
		} fi;
	} else  {
		echo "Usando lista de disponibles de $arcdis" | tee -a /var/tmp/distrib-adJ.bitacora;
	} fi;

	disp=`cat $arcdis`;

	tr " " "\\n" < $arcdis > $arcdis2

	echo "Buscando paquetes sobrantes con respecto a Contenido.txt" | tee -a /var/tmp/distrib-adJ.bitacora
	inv=""
	if (test "$autoMasPaquetesInv" = "s") then {
		inv="-r"
	} fi;
	grep ".-\[v\]" Contenido.txt | sed -e "s/-\[v\]\([-a-zA-Z_0-9]*\).*/-[0-9][0-9alphabetrcvSTABLERCd._]*\1.tgz/g" | sort $inv > tmp/esperados.txt
	ne=`(ls $V$VESP-$ARQ/paquetes/ ; ls $V$VESP-$ARQ/sivel/*tgz) | grep -v -f tmp/esperados.txt`;
	if (test "$ne" != "") then {
		echo "Los siguientes paquetes presentes en el directorio $V$VESP-$ARQ/paquetes no están entre los esperados:" | tee -a /var/tmp/distrib-adJ.bitacora;
		echo $ne | tee -a /var/tmp/distrib-adJ.bitacora;
		echo -n "[ENTER] para continuar: ";
		read;
	} fi;

	echo "Buscando repetidos con respecto a Contenido.txt" | tee -a /var/tmp/distrib-adJ.bitacora
	m=""
	(cd $V$VESP-$ARQ/paquetes; ls ../sivel/*tgz; ls > /tmp/actu2-l)
	for i in `cat tmp/esperados.txt`; do
		n=`grep "^$i" /tmp/actu2-l | wc -l | sed -e "s/ //g"`;
		if (test "$n" -gt "1") then {
			m="enter";
			echo -n "$i $n: "
			echo `grep "^$i" /tmp/actu2-l`;
		} fi;
	done

	if (test "$m" = "enter") then {
		echo "Presione [ENTER] para continuar";
		read;
	} fi;

	rm -f tmp/poract.txt
	t=0;
	for i in `cat tmp/esperados.txt`; do 
		cmd="grep \"^$i\" $arcdis2 | tail -n 1";
		p=`grep "^$i" $arcdis2 | tail -n 1`; 
		echo -n "($p)"
		da=`ls $V$VESP-$ARQ/paquetes/ | grep "^$i"`
		echo -n " -> $p"; 
		e=`grep "^$i" tmp/excluye.txt | tail -n 1`;
		echo " $e"; 
		if (test "$da" != "$p" -a "$p" != "$e" -a "X$p" != "X") then {
			echo $p >> tmp/poract.txt
			t=1;
		} fi;
	done

	if (test "$t" = "1") then {
		pa=`cat tmp/poract.txt | grep . | tr "\n" "," | sed -e "s/,$//g"`
		#	cmd="rsync -avz vtamara@uvirtual.ean.edu.co:'$pa' $V$VESP-$ARQ/paquetes/"
		if (test "$pftp" = "ftp") then {
			cmd="(cd $V$VESP-$ARQ/paquetes; ftp $PKG_PATH/{$pa} )"
		} else {
			echo $pa | grep "," > /dev/null
			if (test "$?" = "0") then {
				cmd="cp $PKG_PATH/{$pa} $V$VESP-$ARQ/paquetes"
			} else {
				cmd="cp $PKG_PATH/$pa $V$VESP-$ARQ/paquetes"
			} fi;
		} fi;
		echo $cmd;
		eval $cmd;
	} else {
		echo "Nada por actualizar";
	} fi;

	echo "Buscando faltantes con respecto a Contenido.txt" | tee -a /var/tmp/distrib-adJ.bitacora
	m=""
	(cd $V$VESP-$ARQ/paquetes; ls > /tmp/actu2-l)
	for i in `cat tmp/esperados.txt`; do  
		n=`grep "^$i" /tmp/actu2-l | wc -l | sed -e "s/ //g"`; 
		if (test "$n" = "0") then {
			echo "$i"
		} fi; 
	done

} fi;

echo " *> Preparar site$VP.tgz" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn="$autoSite"
} fi;


if (test "$sn" = "s") then {
	#Asegurar versiones 
	grep "rsync-adJ $V" arboldd/usr/local/bin/rsync-adJ > /dev/null
	if (test "$?" = "0") then {
		ed arboldd/usr/local/bin/rsync-adJ <<EOF
,s/rsync-adJ $V/rsync-adJ $VS/g
w
q
EOF
	} fi;
	grep "actbase.sh $V" arboldd/usr/local/adJ/actbase.sh > /dev/null
	if (test "$?" = "0") then {
		ed arboldd/usr/local/adJ/actbase.sh <<EOF
,s/actbase.sh $V/actbase.sh $VS/g
w
q
EOF
	} fi;
	mkdir -p /tmp/i
	rm -rf /tmp/i/*
	mkdir -p /tmp/i/usr/local/adJ/
	cp -rf $dini/arboldd/* /tmp/i/
	find /tmp/i -name "*~" | xargs rm 
	cp $dini/arboldd/usr/local/adJ/inst.sh /tmp/i/inst-adJ.sh
	mkdir -p /tmp/i/usr/src/etc/
	cp /usr/src/etc/Makefile  /tmp/i/usr/src/etc/
	for i in `cat $dini/lista-site`; do 
		if (test -d "/destdir/$i" -o -d "$i") then {
			mkdir -p /tmp/i/$i
		} elif (test -f "/destdir/$i") then {
			d=`dirname $i`
			mkdir -p /tmp/i/$d
			cp /destdir/$i /tmp/i/$i
		} else {
			echo "lista-site errada, falta $i en /destdir, intentando de /";
			mkdir -p /tmp/i/`dirname $i`; 
			cp -f /$i /tmp/i/$i	
		} fi;
	done;
	mkdir -p /tmp/i/etc/
	cat > /tmp/i/etc/rc.firsttime <<EOF
/usr/local/adJ/inst-adJ.sh
EOF
	d=`pwd`
	(cd /tmp/i ; tar cvfz $d/$V$VESP-$ARQ/site$VP.tgz .)
} fi;

echo " *> Crear Contenido.txt" | tee -a /var/tmp/distrib-adJ.bitacora;
if (test "$inter" = "-i") then {
	echo -n "(s/n)? "
	read sn
}
else {
	sn="$autoTextos"
} fi;


if (test "$sn" = "s") then {
	echo "s/\[V\]/$V/g"  > tmp/rempCont.sed
	for i in `grep ".-\[v\]" Contenido.txt | sed -e "s/-\[v\]\([-a-zA-Z_0-9]*\).*/-[v]\1/g"`; do
		n=`echo $i | sed -e "s/-\[v\]\([-a-zA-Z_0-9]*\).*/-[0-9][0-9alphabetvrc._]*\1.tgz/g"`
		d=`(cd $V$VESP-$ARQ/paquetes; ls | grep "^$n"; cd ../sivel; ls | grep "^$n" 2>/dev/null | tail -n 1)`
		e=`echo $d | sed -e 's/.tgz//g'`;
		ic=`echo $i | sed -e 's/\[v\]/\\\\[v\\\\]/g'`;
		echo "s/^$ic/$e/g" >> tmp/rempCont.sed
	done;

	sed -f tmp/rempCont.sed Contenido.txt > $V$VESP-$ARQ/Contenido.txt

echo " *> Revisando faltantes con respecto a Contenido.txt" | tee -a /var/tmp/distrib-adJ.bitacora;
	l=`(cd $V$VESP-$ARQ/paquetes; ls *tgz)`
	for i in $l; do 
		n=`echo $i | sed -e "s/-[0-9].*//g"`; 
		grep $n Contenido.txt > /dev/null ; 
		if (test "$?" != "0") then { 
			echo "En Contenido.txt falta $n"; 
		} fi; 
	done
	echo " *> Copiando otros textos";
	if (test -f Actualiza.txt) then {
		cp Actualiza.txt $V$VESP-$ARQ/Actualiza.txt 
	} fi;
	if (test -f Dedicatoria.txt) then {
		cp Dedicatoria.txt $V$VESP-$ARQ/Dedicatoria.txt
	} fi;
	if (test -f Derechos.txt) then {
		cp Derechos.txt $V$VESP-$ARQ/Derechos.txt
	} fi;
	if (test -f Novedades.ewiki) then {
		echo "*** De Ewiki a Texto" | tee -a /var/tmp/distrib-adJ.bitacora
		awk -f hdes/ewikiAtexto.awk Novedades.ewiki > tmp/Novedades.txt
		#recode latin1..utf8 tmp/Novedades.txt
	} fi;
	if (test -f tmp/Novedades.txt) then {
		echo "*** Novedades" | tee -a /var/tmp/distrib-adJ.bitacora;
		cp tmp/Novedades.txt $V$VESP-$ARQ/Novedades.txt
	} fi;
} fi;

echo "** Generando suma sha256" | tee -a /var/tmp/distrib-adJ.bitacora
rm $V$VESP-$ARQ/SHA256
l=`ls $V$VESP-$ARQ`;
cmd="(cd $V$VESP-$ARQ; cksum -a sha256 $l >  SHA256)";
echo $cmd;
eval $cmd;


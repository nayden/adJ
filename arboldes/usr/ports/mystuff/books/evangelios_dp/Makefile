# $OpenBSD$
# This port is released to the public domain.
#

include Make.inc

DISTNAME=	${PNAME}-${V}
PKGNAME=   	${DISTNAME}
CATEGORIES=    	books

MAINTAINER=	Vladimir Támara Patiño <vtamara@pasosdeJesus.org>

HOMEPAGE=	http://traduccion.pasosdeJesus.org
MASTER_SITES=	https://github.com/pasosdeJesus/biblia_dp/archive/
DISTFILES=	v${V}.zip

WRKDIST=        ${WRKDIR}/biblia_dp-${V}

#Public domain
PERMIT_PACKAGE_CDROM=	Yes
PERMIT_PACKAGE_FTP=	Yes
PERMIT_DISTFILES_FTP=	Yes

CONFIGURE_STYLE=        simple
CONFIGURE_SCRIPT=       conf.sh
CONFIGURE_ARGS+=-p ${PREFIX}

BUILD_DEPENDS=  textproc/docbook-xsl textproc/docbook-dsssl textproc/docbook textproc/openjade print/texlive/base print/texlive/texmf


INSTALL_TARGET = instala
ALL_TARGET = multi

do-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/evangelios_dp
	${INSTALL_DATA} ${WRKBUILD}/html/* ${PREFIX}/share/doc/evangelios_dp

post-install:

.include <bsd.port.mk>

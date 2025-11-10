#!/bin/sh -e

do_install() {
	target="$1"
	pkgname=hexagon-dsp-binaries-$(echo $target | sed -e 's!^[^/]*/!!g' | tr A-Z/_ a-z--)
	if [ ! -e "debian/${pkgname}.install" ]
	then
		devname=$(echo ${target} | sed -e 's!^[^/]*/!!g' -e 's!/! !g')

		if [ -z "${PACKAGES}" ]
		then
			PACKAGES="${pkgname}"
		else
			PACKAGES="${PACKAGES}, ${pkgname}"
		fi

		# XXX: currently the packages depend on the exact
		# linux-firmware-soc version that provides corresponding DSP
		# binaries. This will be relaxed once linux-firmware-qcom-soc
		# starts providing virtual package names for DSP binaries.
		echo >> debian/control.tmp2
		sed -e "s!#PKGNAME#!${pkgname}!g" -e "s!#DEVNAME#!${devname}!g" -e "s!#VERSION#!${VERSION}!g" \
			debian/control.dev.in >> debian/control.tmp2

		echo "# Automatically generated file, modify debian/regen.sh instead" > debian/${pkgname}.install
		echo "usr/share/hexagon-dsp/${target}/dsp/*/*.so*" >> debian/${pkgname}.install
		echo "usr/share/hexagon-dsp/${target}/dsp/*/fastrpc_shell*" >> debian/${pkgname}.install

		echo "# Automatically generated file, modify debian/regen.sh or debian/pkgname.lintian-overrides.in instead" > debian/${pkgname}.lintian-overrides
		sed -e "s!#PKGNAME#!${pkgname}!g" debian/pkgname.lintian-overrides.in >> debian/${pkgname}.lintian-overrides

		echo "WHENCE" >> debian/${pkgname}.docs
	fi
}

rm -f debian/hexagon-dsp-binaries-*.install
rm -f debian/hexagon-dsp-binaries-*.lintian-overrides
rm -f debian/control.tmp debian/control.tmp2

PACKAGES=""
VERSION="$1"

cat debian/control.head.in > debian/control.tmp

while read verb target rest
do
	case ${verb} in
		"#" | "" )
			;;
		"Install:" )
			do_install ${target}
			;;
		* )
			echo "Unsupported clause ${verb}" >&2
			exit 1
	esac
done < config.txt

echo >> debian/control.tmp
sed -e "s!#PACKAGES#!${PACKAGES}!g" debian/control.main.in >> debian/control.tmp

cat debian/control.tmp2 >> debian/control.tmp

mv debian/control.tmp debian/control

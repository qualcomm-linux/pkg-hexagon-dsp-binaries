#!/bin/sh -e

do_lintian_override() {
	pkgname="$1"

	echo "# Automatically generated file, modify debian/regen.sh or debian/pkgname.lintian-overrides.in instead" > debian/${pkgname}.lintian-overrides
	sed -e "s!#PKGNAME#!${pkgname}!g" debian/all.lintian-overrides.in >> debian/${pkgname}.lintian-overrides
}

add_package() {
	pkgname="$1"

	if ! grep -q "Package: ${pkgname}$" debian/control.tmp2 ; then
		if [ -z "${PACKAGES}" ]
		then
			PACKAGES="${pkgname}"
		else
			PACKAGES="${PACKAGES}, ${pkgname}"
		fi

		devname=$(echo ${target} | sed -e 's!^[^/]*/!!g' -e 's!/! !g')

		# XXX: currently the packages depend on the exact
		# linux-firmware-soc version that provides corresponding DSP
		# binaries. This will be relaxed once linux-firmware-qcom-soc
		# starts providing virtual package names for DSP binaries.
		echo >> debian/control.tmp2
		sed -e "s!#PKGNAME#!${pkgname}!g" -e "s!#DEVNAME#!${devname}!g" -e "s!#VERSION#!${VERSION}!g" \
			debian/control.dev.in >> debian/control.tmp2

		if [ ! -e "debian/${pkgname}.install" ]
		then
			echo "# Automatically generated file, modify debian/regen.sh instead" > debian/${pkgname}.install
		fi

		echo "WHENCE" > debian/${pkgname}.docs
		touch debian/${pkgname}.tmp-deps

		do_lintian_override ${pkgname}
	fi
}

skip_soc() {
	# skip first pathname entry
	sed -e 's!^[^/]*/!!g'
}

device_name() {
	# keep first two pathname entries
	sed -e 's!\([^/]*/[^/]*\)/.*!\1!g'
}

to_pkgname() {
	tr A-Z/_ a-z-- | sed -e 's!^!hexagon-dsp-binaries-!'
}

do_install() {
	target="$1"
	pkgname=$(echo $target | skip_soc | to_pkgname)
	add_package ${pkgname}

	if ! grep -q unstripped debian/${pkgname}.lintian-overrides ; then
		sed -e "s!#PKGNAME#!${pkgname}!g" debian/pkgname.lintian-overrides.in >> debian/${pkgname}.lintian-overrides
	fi

	echo "usr/share/hexagon-dsp/${target}/dsp/*/*.so*" >> debian/${pkgname}.install
	echo "usr/share/hexagon-dsp/${target}/dsp/*/fastrpc_shell*" >> debian/${pkgname}.install
}

do_link() {
	src="$1"
	target="$2"
	spkgname=$(echo $src | skip_soc | device_name | to_pkgname)
	pkgname=$(echo $target | skip_soc | device_name | to_pkgname)

	add_package ${pkgname}
	echo "$spkgname" >> debian/${pkgname}.tmp-deps

	echo "usr/share/hexagon-dsp/${target}" >> debian/${pkgname}.install
}

rm -f debian/hexagon-dsp-binaries.lintian-overrides
rm -f debian/hexagon-dsp-binaries-*.docs
rm -f debian/hexagon-dsp-binaries-*.install
rm -f debian/hexagon-dsp-binaries-*.lintian-overrides
rm -f debian/hexagon-dsp-binaries-*.tmp-deps
rm -f debian/control.tmp debian/control.tmp2

PACKAGES=""
VERSION="$1"

cat debian/control.head.in > debian/control.tmp

do_lintian_override hexagon-dsp-binaries

touch debian/control.tmp2
while read verb target rest
do
	case ${verb} in
		"#" | "" )
			;;
		"Install:" )
			do_install ${target}
			;;
		"Link:" )
			do_link ${target} ${rest}
			;;
		* )
			echo "Unsupported clause ${verb}" >&2
			exit 1
	esac
done < config.txt

echo >> debian/control.tmp
sed -e "s!#PACKAGES#!${PACKAGES}!g" debian/control.main.in >> debian/control.tmp

for deps in debian/hexagon-dsp-binaries-*.tmp-deps ; do
	pkg=$(basename $deps .tmp-deps)
	deps=$(sort $deps | uniq | sed -e 's/$/, /g')
	sed -i -e "s/#${pkg}-DEPS#/${deps}/g" debian/control.tmp2
done

cat debian/control.tmp2 >> debian/control.tmp

mv debian/control.tmp debian/control

rm -f debian/*.tmp*

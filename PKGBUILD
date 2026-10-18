# Maintainer: lnbodicherla <ln.bodicherla@pm.me>
pkgname=omarchy-mac-keys
pkgver=0.1.0
pkgrel=1
pkgdesc="macOS keyboard shortcuts, per app, for Omarchy (Hyprland)"
arch=('any')
url="https://github.com/CHANGE-ME/omarchy-mac-keys"
license=('MIT')
depends=('hyprland>=0.56' 'jq' 'python')
optdepends=('ghostty: terminal shortcuts like ⌘K')
checkdepends=('lua')
install=omarchy-mac-keys.install
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

check() {
  cd "$pkgname-$pkgver"
  make test
}

package() {
  cd "$pkgname-$pkgver"
  make DESTDIR="$pkgdir" PREFIX=/usr install
}

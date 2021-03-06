require 'formula'

class Tophat < Formula
  url 'http://tophat.cbcb.umd.edu/downloads/tophat-1.3.2.tar.gz'
  homepage 'http://tophat.cbcb.umd.edu/'
  md5 'b214c54928805eb1095828b1c7c1bbab'

  depends_on 'samtools'

  def install
    # It seems this project Makefile doesn't like -j4
    # Disable until consult with upstream
    ENV.deparallelize

    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end

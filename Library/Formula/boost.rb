require 'formula'

class Boost < Formula
  homepage 'http://www.boost.org'
  url 'http://downloads.sourceforge.net/project/boost/boost/1.47.0/boost_1_47_0.tar.bz2'
  md5 'a2dc343f7bc7f83f8941e47ed4a18200'
  bottle 'https://downloads.sourceforge.net/project/machomebrew/Bottles/boost-1.47.0-bottle.tar.gz'
  bottle_sha1 '4f3834fb471c3fac20c649bc4081ddde991e4b3b'

  def options
    [
      ["--with-mpi", "Enable MPI support"],
      ["--universal", "Build universal binaries"],
      ["--without-python", "Build without Python"]
    ]
  end

  # Both clang and llvm-gcc provided by XCode 4.1 compile Boost 1.47.0 properly.
  # Moreover, Apple LLVM compiler 2.1 is now among primary test compilers.
  if MacOS.xcode_version < "4.1"
    fails_with_llvm "LLVM-GCC causes errors with dropped arguments to functions when linking with boost"
  end

  def install
    if ARGV.build_universal? and not ARGV.include? "--without-python"
      archs = archs_for_command("python")
      unless archs.universal?
        opoo "A universal build was requested, but Python is not a universal build"
        puts "Boost compiles against the Python it finds in the path; if this Python"
        puts "is not a universal build then linking will likely fail."
      end
    end

    # Adjust the name the libs are installed under to include the path to the
    # Homebrew lib directory so executables will work when installed to a
    # non-/usr/local location.
    #
    # otool -L `which mkvmerge`
    # /usr/local/bin/mkvmerge:
    #   libboost_regex-mt.dylib (compatibility version 0.0.0, current version 0.0.0)
    #   libboost_filesystem-mt.dylib (compatibility version 0.0.0, current version 0.0.0)
    #   libboost_system-mt.dylib (compatibility version 0.0.0, current version 0.0.0)
    #
    # becomes:
    #
    # /usr/local/bin/mkvmerge:
    #   /usr/local/lib/libboost_regex-mt.dylib (compatibility version 0.0.0, current version 0.0.0)
    #   /usr/local/lib/libboost_filesystem-mt.dylib (compatibility version 0.0.0, current version 0.0.0)
    #   /usr/local/libboost_system-mt.dylib (compatibility version 0.0.0, current version 0.0.0)
    inreplace 'tools/build/v2/tools/darwin.jam', '-install_name "', "-install_name \"#{HOMEBREW_PREFIX}/lib/"

    # Force boost to compile using the appropriate GCC version
    open("user-config.jam", "a") do |file|
      file.write "using darwin : : #{ENV['CXX']} ;\n"
      file.write "using mpi ;\n" if ARGV.include? '--with-mpi'
    end

    args = ["--prefix=#{prefix}",
            "--libdir=#{lib}",
            "-j#{Hardware.processor_count}",
            "--layout=tagged",
            "--user-config=user-config.jam",
            "threading=multi",
            "install"]

    args << "address-model=32_64" << "architecture=x86" << "pch=off" if ARGV.include? "--universal"
    args << "--without-python" if ARGV.include? "--without-python"

    # we specify libdir too because the script is apparently broken
    system "./bootstrap.sh", "--prefix=#{prefix}", "--libdir=#{lib}"
    system "./bjam", *args
  end
end

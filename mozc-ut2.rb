# Documentation: https://docs.brew.sh/Formula-Cookbook.html
#                http://www.rubydoc.info/github/Homebrew/brew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class MozcUt2 < Formula
  desc 'Mozc with UT2 Dictionary'
  homepage 'http://www.geocities.jp/ep3797/mozc-ut2.html'
  url "https://osdn.net/frs/chamber_redir.php?m=iij&f=%2Fusers%2F16%2F16039%2Fmozcdic-ut2-20171008.tar.bz2"
  version "20171008"
  sha256 "fad6ae12f8ee918222d376d124a892fc233ab1159f7e551c4cffe1e3203af3fb"
  
  # options
  option 'with-qt', "Build with Qt"
  option 'with-emacs', 'Build emacs support files'
  option 'with-tarball', 'Generate source tarball for Arch Linux (pkgbuild)'
  option 'with-ejdic', 'Generate the English-Japanese dictionary'
  option 'with-nicodic', 'Generate the Niconico dictionary'

  # dependencies
  depends_on :xcode => :build
  depends_on 'ninja' => :build
  depends_on 'qt5' if build.with? 'qt'
  
  # resources
  resource 'mozc' do
    url 'https://github.com/google/mozc.git', :revision => '4767ce2f2b6a63f1f139daea6e98bc7a564d5e4e'
  end
  resource "ken_all" do
    url 'http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip'
    # check on 2017/12/27
    sha256 'e6d0132b94ab867ca6258ac001a2b13e7b4473ff009d7d3e9ccbca80566d6512'
  end
  resource "jigyousyo" do
    url 'http://www.post.japanpost.jp/zipcode/dl/jigyosyo/zip/jigyosyo.zip'
    # check on 2017/12/27
    sha256 'f94e847dead0e7cb8f5f2f2323701f8f878ba5da9d2da03c9de77281601695c1'
  end
  resource "edict" do
    url 'http://ftp.monash.edu.au/pub/nihongo/edict.gz'
    # check on 2017/12/27
    sha256 'eb2315525bf3291d967872b1a918f2b76c859cbb78d7cccb53de9a1b367debb0'
  end

  
  MOZCVER="2.20.2677.102"
  DICVER="20171008"

  def install
    mozcdic_ut2 = Pathname.pwd
    mozc_ut2 = "mozc-ut2-#{MOZCVER}.#{DICVER}"
    # mozc absolute path
    mozc = mozcdic_ut2/mozc_ut2
    resource('mozc').stage do
      if build.with? 'emacs'
        # * enable build unix/emacs
        p = Patch.create(:p1, :DATA)
        p.path = Pathname.new(__FILE__).expand_path
        p.apply
      end
      mv Pathname.pwd, mozc
    end
    # "filter mozc entries..."
    Dir.chdir 'src' do
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary00.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary01.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary02.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary03.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary04.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary05.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary06.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary07.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary08.txt'
      system 'ruby', 'filter-mozc-entries.rb', mozc/'src/data/dictionary_oss/dictionary09.txt'
      
      Dir.glob(mozc/'src/data/dictionary_oss/*.txt.filt') do |file|
        mv file, file.gsub( /\.txt\.filt$/, '.txt')
      end

      # "remove mozc duplicates..."
      system "cat #{mozc}/src/data/dictionary_oss/dictionary*.txt > mozcdict"
      system 'ruby', 'remove-mozc-duplicates.rb', 'mozcdict'
      mv 'mozcdict.remdup', 'mozcdict'
      
      # get hinsi ID
      cp mozc/'src/data/dictionary_oss/id.def', '.'

    end
    # ==============================================================================
    # generate placenames and ZIP codes
    # ==============================================================================

    # get zip code data
    resource('ken_all').stage do
      cp 'KEN_ALL.csv', mozcdic_ut2/'chimei'
    end
    resource('jigyousyo').stage do
      cp 'JIGYOSYO.CSV', mozcdic_ut2/'chimei'
    end
    
    Dir.chdir 'chimei' do
      # modify zip code data
      system 'ruby', 'modify-zipcode.rb', 'KEN_ALL.CSV'

      cp mozc/'src/dictionary/gen_zip_code_seed.py', '.'
      cp mozc/'src/dictionary/zip_code_util.py', '.'

      # temporary fix
      inreplace 'gen_zip_code_seed.py', 'from dictionary import zip_code_util', 'import zip_code_util'

      # generate zip code entries
      system '/usr/bin/python gen_zip_code_seed.py --zip_code=KEN_ALL.CSV.modzip --jigyosyo=JIGYOSYO.CSV > ../src/zipcode.costs'

      # generate chimei costs
      system 'ruby', 'get-chimei-costs.rb', 'KEN_ALL.CSV.modzip'
    end

    # ==============================================================================
    # generate ut doctionary
    # ==============================================================================
    system 'cat */*.hits */*.hits.modhits > src/jawikihits_all'
    Dir.chdir 'src' do
      if build.with? 'nicodic'
	    system 'cat jawikihits_all ../niconico/niconico.hits > jawikihits_all.new'
	    mv 'jawikihits_all.new', 'jawikihits_all'
      end
      # change mozcdic order...
      system 'ruby', 'change-mozcdic-order-to-utdic-order.rb', 'mozcdict'
      # convert jawikihits to costs...
      system 'ruby', 'convert-jawikihits-to-costs.rb', 'jawikihits_all'
    end
    # generate ekimei costs
    Dir.chdir 'ekimei' do
      system 'ruby', 'generate-ekimei-costs.rb', 'ekimei.hits'
    end
    Dir.chdir 'src' do
      system <<-EOS.undent
          cat mozcdict.utorder jawikihits_all.costs \
            ../chimei/KEN_ALL.CSV.modzip.costs \
            ../edict-katakana-english/kanaeng.costs \
            ../ekimei/ekimei.costs > utdict.costs
          EOS
      
      if build.with? 'ejdic'
	    system 'cat utdict.costs ../wordnet-ejdic/wordnet-ejdic.costs > utdict.costs.new'
	    mv 'utdict.costs.new', 'utdict.costs'
      end

      # split new words and add id...
      system 'ruby', 'split-new-words-and-add-id.rb', 'utdict.costs'
      mv 'utdict.costs.new', 'utdict.costs'

      system "cat utdict.costs zipcode.costs #{mozc}/src/data/dictionary_oss/dictionary00.txt > dictionary00.txt"
      mv 'dictionary00.txt', mozc/'src/data/dictionary_oss'
    end
    
    # change mozc branding
    Dir.chdir mozc/'src/base' do
      inreplace 'const.h', "\"Mozc\"", "\"Mozc-UT2\""
    end

    if build.with? 'tarball'
      # copy docs and PKGBUILD
      mkdir_p mozc/'docs-ut/'
      cp 'AUTHORS', mozc/'docs-ut/'
      cp 'ChangeLog', mozc/'docs-ut/'
      cp 'COPYING',  mozc/'docs-ut/'
      cp 'README.md', mozc/'docs-ut/'
      cp 'PKGBUILD', mozc
      cp_r 'docs/', mozc/'docs-ut/'
      if ! build.without? 'ejdic'
	    rm_rf  mozc/'docs-ut/wordnet-ejdic/'
      end
      if ! build.without? 'nicodic'
	    rm_rf  mozc/'docs-ut/niconico/'
      end
      system "COPYFILE_DISABLE=1 tar -jcf --exclude=\'.git\' --exclude=\'.svn\' -f #{mozc_ut2}.tar.bz2 #{mozc_ut2}"
      prefix.install "#{mozc_ut2}.tar.bz2"
    end
    # build mozc
    Dir.chdir mozc/'src' do
      # prebuild
      m = "#{MacOS.sdk_path}".match(/(10.[0-9]+)/)
      sdk_version = m[1]
      prebuild_cmd = "GYP_DEFINES=\"mac_sdk=#{sdk_version} mac_deployment_target=10.9\" /usr/bin/python build_mozc.py gyp --branding Mozc-UT2"
      if build.with? 'qt'
        prebuild_cmd << " --qtdir #{Formula["qt5"].opt_prefix}"
      else
        prebuild_cmd << " --noqt"
      end
      system prebuild_cmd
      
      # build
      # Foce to use macos python2,
      # ninja fail to build if exist /usr/local/python.
      build_cmds  = 'PATH=/usr/bin:$PATH /usr/bin/python build_mozc.py build -c Release mac/mac.gyp:GoogleJapaneseInput mac/mac.gyp:gen_launchd_confs'
      if build.with? 'emacs'
        build_cmds << ' unix/emacs/emacs.gyp:mozc_emacs_helper'
      end
      system build_cmds
      
      # install
      prefix.install "out_mac/Release/Mozc-UT2.app"
      prefix.install "out_mac/Release/gen/mac/org.mozc.inputmethod.Japanese.Converter.plist"
      prefix.install "out_mac/Release/gen/mac/org.mozc.inputmethod.Japanese.Renderer.plist"

      if build.with? 'emacs'
        bin.install "out_mac/Release/mozc_emacs_helper"
        (share/"emacs/site-lisp").install "unix/emacs/mozc.el"
      end
      (prefix/"install-mozc-ut2.sh").write <<-EOS.undent
          #!/bin/sh
          cd `dirname $0`
          if [ -e /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Converter.plist ]; then
            launchctl stop /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Converter.plist
          fi
          if [ -e /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Renderer.plist ]; then
            launchctl stop /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Renderer.plist
          fi
          ln -sf #{opt_prefix}/Mozc-UT2.app "/Library/Input Methods"
          ln -sf #{opt_prefix}/org.mozc.inputmethod.Japanese.*.plist /Library/LaunchAgents
        EOS
      (prefix/"uninstall-mozc-ut2.sh").write <<-EOS.undent
          #!/bin/sh
          cd `dirname $0`
          if [ -e /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Converter.plist ]; then
            launchctl stop /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Converter.plist
          fi
          if [ -e /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Renderer.plist ]; then
            launchctl stop /Library/LaunchAgents/org.mozc.inputmethod.Japanese.Renderer.plist
          fi
          rm -rf "/Library/Input Methods/Mozc-UT2.app"
          rm -rf /Library/LaunchAgents/org.mozc.inputmethod.Japanese.*.plist
        EOS
    end
  end
  
  def caveats
    s = <<-EOS.undent

      To complete installation, execute the following shell commaond:
        sudo sh #{opt_prefix}/install-mozc-ut2.sh
      and then login again.
      If you want uninstall Mozc, execute the following shell commaond before 'brew uninstall'
        sudo sh #{opt_prefix}/uninstall-mozc-ut2.sh
    EOS
    if build.with? 'emacs'
      s += <<-EOS.undent

        mozc-mode supports LEIM (Library of Emacs Input Method) and
        you only need the following settings in your init file
        (~/.emacs.d/init.el or ~/.emacs).

          (require 'mozc)  ; or (load-file "/path/to/mozc.el")
          (setq default-input-method "japanese-mozc")
      EOS
    end
    s += <<-EOS.undent

      #{Tty.red}* attention *#{Tty.reset}
      Input Method need to be placed system-specific location.
      Please use 'install-mozc-ut2.sh', don't follow install instruction below.
    EOS
    s
  end
  
  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test hogehoge`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end

# manual patching
#  * enabling build emacs
__END__
diff --git a/src/build_mozc.py b/src/build_mozc.py
index a7a534a4..71a069f4 100644
--- a/src/build_mozc.py
+++ b/src/build_mozc.py
@@ -179,6 +179,9 @@ def GetGypFileNames(options):
   elif options.target_platform == 'Android':
     # Add Android Mozc gyp scripts.
     gyp_file_names.extend(glob.glob('%s/android/*/*.gyp' % SRC_DIR))
+  elif options.target_platform == 'Mac':
+    # Add mozc_emacs_helper gyp scripts.
+    gyp_file_names.extend(glob.glob('%s/unix/emacs/emacs.gyp' % SRC_DIR))
   gyp_file_names.sort()
   return gyp_file_names

{
  common_vm: ${common} ${vm_setup} {
    python_version: 3,
    logs: [
      "*/mxbuild/dists/stripped/*.map"
      "**/install.packages.R.log"
    ]
  }

  common_vm_linux: ${common_vm} ${linux} {
    packages: {
      devtoolset: "==7" # GCC 7.3.1, make 4.2.1, binutils 2.28, valgrind 3.13.0
    }
  }

  common_vm_darwin: ${common_vm} ${darwin} {
    packages: {
      gcc: "==4.9.2"
    }
    environment: {
      LANG: en_US.UTF-8
      # for compatibility with macOS Sierra
      MACOSX_DEPLOYMENT_TARGET: "10.13"
    }
    setup: ${common_vm.setup}
  }

  common_vm_windows: ${common_vm} ${windows} {
    downloads : {
      MAVEN_HOME: {name: maven, version: "3.3.9", platformspecific: false}
    }
    environment : {
      PATH : "$MAVEN_HOME\bin;$JAVA_HOME\bin;$PATH"
    }
  }

  common_vm_windows-jdk11: ${common_vm} ${windows} ${devkits.windows-jdk11} {
    downloads : {
      MAVEN_HOME: {name: maven, version: "3.3.9", platformspecific: false}
    }
    environment : {
      PATH : "$MAVEN_HOME\bin;$JAVA_HOME\bin;$PATH"
    }
  }

  common_vm_windows-jdk17: ${common_vm} ${windows} ${devkits.windows-jdk17} {
    downloads : {
      MAVEN_HOME: {name: maven, version: "3.3.9", platformspecific: false}
    }
    environment : {
      PATH : "$MAVEN_HOME\bin;$JAVA_HOME\bin;$PATH"
    }
  }

  # JS
  js_windows_common: {
    downloads: {
      NASM: {name: nasm, version: "2.14.02", platformspecific: true}
    }
  }

  js_windows_jdk11: ${common_vm_windows-jdk11} ${js_windows_common} {
    setup: ${common_vm_windows-jdk11.setup} [
      # Keep in sync with the "devkits" object defined in the top level common.json file.
      # When this file has been converted to jsonnet, the value can be computed instead
      # using Jsonnet std lib functions.
      ["set-export", "DEVKIT_VERSION", "2017"]
    ]
  }

  js_windows_jdk17: ${common_vm_windows-jdk17} ${js_windows_common} {
    setup: ${common_vm_windows-jdk17.setup} [
      # Keep in sync with the "devkits" object defined in the top level common.json file.
      # When this file has been converted to jsonnet, the value can be computed instead
      # using Jsonnet std lib functions.
      ["set-export", "DEVKIT_VERSION", "2019"]
    ]
  }

  js_windows: ${common_vm_windows} ${js_windows_common} {
    setup: ${common_vm_windows.setup} [
      # Keep in sync with the "devkits" object defined in the top level common.json file.
      # When this file has been converted to jsonnet, the value can be computed instead
      # using Jsonnet std lib functions.
      ["set-export", "DEVKIT_VERSION", "2017"]
    ]
  }

  # SULONG
  sulong_linux: ${sulong.deps.common} ${sulong.deps.linux}
  sulong_darwin: ${sulong.deps.common} ${sulong.deps.darwin}

  # TRUFFLERUBY
  truffleruby_linux: ${sulong_linux} ${truffleruby.deps.common} ${truffleruby.deps.linux}

  truffleruby_darwin: ${sulong_darwin} ${truffleruby.deps.common} ${truffleruby.deps.darwin}

  # FASTR
  # Note: On both Linux and MacOS, FastR depends on the gnur module and on gfortran
  # of a specific version (4.8.5 on Linux, 10.2.0 on MacOS)
  # However, we do not need to load those modules, we only configure specific environment variables to
  # point to these specific modules. These modules and the configuration is only necessary for installation of
  # some R packages (that have Fortran code) and in order to run GNU-R

  fastr: {
    environment: {
      FASTR_RELEASE: "true"
    }
    downloads: {
      F2C_BINARY: { name: "f2c-binary", version: "7", platformspecific: true },
      FASTR_RECOMMENDED_BINARY: { name: "fastr-recommended-pkgs", version: "12", platformspecific: true },
    }
    catch_files: ${common.catch_files} [
      "GNUR_CONFIG_LOG = (?P<filename>.+\\.log)",
      "GNUR_MAKE_LOG = (?P<filename>.+\\.log)",
    ]
  }

  fastr_linux: ${fastr} {
    packages: {
      readline: "==6.3",
      pcre2: "==10.37",
      zlib: ">=1.2.11",
      curl: ">=7.50.1",
      gnur: "==4.0.3-gcc4.8.5-pcre2"
    }
    environment: {
      TZDIR: "/usr/share/zoneinfo"
      PKG_INCLUDE_FLAGS_OVERRIDE : "-I/cm/shared/apps/zlib/1.2.11/include -I/cm/shared/apps/bzip2/1.0.6/include -I/cm/shared/apps/xz/5.2.2/include -I/cm/shared/apps/pcre2/10.37/include -I/cm/shared/apps/curl/7.50.1/include"
      PKG_LDFLAGS_OVERRIDE : "-L/cm/shared/apps/zlib/1.2.11/lib -L/cm/shared/apps/bzip2/1.0.6/lib -L/cm/shared/apps/xz/5.2.2/lib -L/cm/shared/apps/pcre2/10.37/lib -L/cm/shared/apps/curl/7.50.1/lib -L/cm/shared/apps/gcc/4.8.5/lib64"
      FASTR_FC: "/cm/shared/apps/gcc/4.8.5/bin/gfortran"
      FASTR_CC: "/cm/shared/apps/gcc/4.8.5/bin/gcc"
      GNUR_HOME_BINARY: "/cm/shared/apps/gnur/4.0.3_gcc4.8.5_pcre2-10.37/R-4.0.3"
    }
    downloads: {
      BLAS_LAPACK_DIR: { name: "fastr-403-blas-lapack-gcc", version: "4.8.5", platformspecific: true },
    }
  }

  fastr_darwin: ${fastr} {
    packages: {
      "pcre2": "==10.37",
    }
    environment:  {
      PATH : "/usr/local/bin:$JAVA_HOME/bin:$PATH"
      FASTR_FC: "/cm/shared/apps/gcc/8.3.0/bin/gfortran"
      FASTR_CC: "/cm/shared/apps/gcc/8.3.0/bin/gcc"
      TZDIR: "/usr/share/zoneinfo"
      FASTR_LIBZ_VER: "1.2.11"
      PKG_INCLUDE_FLAGS_OVERRIDE : "-I/cm/shared/apps/pcre2/pcre2-10.37/include -I/cm/shared/apps/bzip2/1.0.6/include -I/cm/shared/apps/xz/5.2.2/include -I/cm/shared/apps/curl/7.50.1/include"
      PKG_LDFLAGS_OVERRIDE : "-L/cm/shared/apps/bzip2/1.0.6/lib -L/cm/shared/apps/xz/5.2.2/lib -L/cm/shared/apps/pcre2/pcre2-10.37/lib -L/cm/shared/apps/curl/7.50.1/lib -L/cm/shared/apps/gcc/10.2.0/lib -L/usr/lib"
    }
    downloads: {
      BLAS_LAPACK_DIR: { name: "fastr-403-blas-lapack-gcc", version: "8.3.0", platformspecific: true },
    }
  }

  fastr_no_recommended: {
    environment: {
      FASTR_NO_RECOMMENDED: "true"
    }
  }

  # GRAALPYTHON
  graalpython_linux: ${sulong_linux} {
    packages: {
      libffi: ">=3.2.1",
      bzip2: ">=1.0.6",
    }
  }

  graalpython_darwin: ${sulong_darwin} {}

  vm_linux: ${common_vm_linux} {
    capabilities: [linux, amd64, manycores, ram16gb, fast]
  }

  vm_linux_aarch64: ${common_vm_linux} {
    capabilities: [linux, aarch64]
  }

  vm_darwin: ${common_vm_darwin} {
    capabilities: [darwin_mojave, amd64, ram16gb]
  }

  vm_windows: ${common_vm_windows} {
    capabilities: [windows_server_2016, amd64]
  }

  vm_windows-jdk11: ${common_vm_windows-jdk11} {
    capabilities: [windows_server_2016, amd64]
  }

  vm_windows-jdk17: ${common_vm_windows-jdk17} {
    capabilities: [windows_server_2016, amd64]
  }

  gate_vm_linux: ${vm_linux} {
    targets: [gate]
  }

  gate_vm_linux_aarch64: ${vm_linux_aarch64} {
    targets: [gate]
  }

  gate_vm_darwin: ${vm_darwin} {
    targets: [gate]
  }

  gate_vm_windows: ${vm_windows} {
    targets: [gate]
  }

  bench_vm_linux: ${vm_linux} {
    targets: [bench, post-merge]
  }

  bench_vm_darwin: ${vm_darwin} {
    targets: [bench, post-merge]
  }

  bench_daily_vm_linux: ${vm_linux} {
    targets: [bench, daily]
  }

  bench_daily_vm_darwin: ${vm_darwin} {
    targets: [bench, daily]
  }

  deploy_vm_linux: ${vm_linux} {
    targets: [deploy, post-merge]
  }

  deploy_vm_linux_aarch64: ${vm_linux_aarch64} {
    targets: [deploy, post-merge]
  }

  deploy_daily_vm_linux: ${vm_linux} {
    targets: [deploy, daily]
  }

  deploy_daily_vm_linux_aarch64: ${vm_linux_aarch64} {
    targets: [deploy, daily]
  }

  deploy_daily_vm_darwin: ${vm_darwin} {
    targets: [deploy, daily]
  }

  deploy_daily_vm_windows: ${vm_windows} {
    targets: [deploy, daily]
  }

  deploy_daily_vm_windows-jdk11: ${vm_windows-jdk11} {
    targets: [deploy, daily]
  }

  deploy_daily_vm_windows-jdk17: ${vm_windows-jdk17} {
    targets: [deploy, daily]
  }

  postmerge_vm_linux: ${vm_linux} {
    targets: [post-merge]
  }

  postmerge_vm_darwin: ${vm_darwin} {
    targets: [post-merge]
  }

  daily_vm_linux: ${vm_linux} {
    targets: [daily]
  }

  daily_vm_darwin: ${vm_darwin} {
    targets: [daily]
  }

  weekly_vm_linux: ${vm_linux} {
    targets: [weekly]
  }

  weekly_vm_darwin: ${vm_darwin} {
    targets: [weekly]
  }

  ondemand_vm_linux: ${vm_linux} {
    targets: [ondemand]
  }

  ondemand_vm_darwin: ${vm_darwin} {
    targets: [ondemand]
  }

  mx_vm_cmd_suffix: ["--sources=sdk:GRAAL_SDK,truffle:TRUFFLE_API,compiler:GRAAL,substratevm:SVM", --with-debuginfo, "--base-jdk-info=${BASE_JDK_NAME}:${BASE_JDK_VERSION}"]
  mx_vm_common: [mx, --env, "${VM_ENV}"] ${mx_vm_cmd_suffix}
  mx_vm_installables: [mx, --env, "${VM_ENV}-complete"] ${mx_vm_cmd_suffix}

  maven_deploy_sdk: [--suite, sdk, maven-deploy, --validate, none, --all-distribution-types, --with-suite-revisions-metadata]
  maven_deploy_sdk_base:               ${maven_deploy_sdk} [--tags, graalvm,                             ${binaries-repository}]
  maven_deploy_sdk_base_dry_run:       ${maven_deploy_sdk} [--tags, graalvm,                  --dry-run, ${binaries-repository}]
  maven_deploy_sdk_components:         ${maven_deploy_sdk} [--tags, "installable,standalone",            ${binaries-repository}]
  maven_deploy_sdk_components_dry_run: ${maven_deploy_sdk} [--tags, "installable,standalone", --dry-run, ${binaries-repository}]

  ruby_vm_build_linux: ${svm-common-linux-amd64} ${sulong_linux} ${truffleruby_linux} ${custom_vm_linux}
  full_vm_build_linux: ${ruby_vm_build_linux} ${fastr_linux} ${graalpython_linux}
  full_vm_build_linux_aarch64: ${svm-common-linux-aarch64} ${sulong_linux} ${custom_vm_linux}

  ruby_vm_build_darwin: ${svm-common-darwin} ${sulong_darwin} ${truffleruby_darwin} ${custom_vm_darwin}
  full_vm_build_darwin: ${ruby_vm_build_darwin} ${fastr_darwin} ${graalpython_darwin}

  libgraal_build_ea_only: [mx,
      --env, ${libgraal_env},
      # enable ea asserts in the image building code
      "--extra-image-builder-argument=-J-ea",
      # enable ea asserts in the generated libgraal
      "--extra-image-builder-argument=-ea",
      build
  ]
  libgraal_build: [mx,
      --env, ${libgraal_env},
      # enable all asserts in the image building code
      "--extra-image-builder-argument=-J-esa",
      "--extra-image-builder-argument=-J-ea",
      # enable all asserts in the generated libgraal
      "--extra-image-builder-argument=-esa",
      "--extra-image-builder-argument=-ea",
      build
  ]
  libgraal_compiler: ${svm-common-linux-amd64} ${custom_vm_linux} ${vm_linux} {
    run: [
      # enable asserts in the JVM building the image and enable asserts in the resulting native image
      ${libgraal_build}
      [mx, --env, ${libgraal_env}, gate, --task, "LibGraal Compiler"]
    ]
    timelimit: "1:00:00"
    targets: [gate]
  }
  libgraal_truffle: ${svm-common-linux-amd64} ${custom_vm_linux} ${vm_linux} {
    environment: {
      # The Truffle TCK tests run as a part of Truffle TCK gate
      TEST_LIBGRAAL_EXCLUDE: "com.oracle.truffle.tck.tests.*"
    }
    run: [
      # -ea assertions are enough to keep execution time reasonable
      ${libgraal_build_ea_only}
      [mx, --env, ${libgraal_env}, gate, --task, "LibGraal Truffle"]
    ]
    logs: ${common_vm.logs} ["*/graal-compiler.log", "*/es-*.json"]
    timelimit: "45:00"
    targets: [gate]
  }


  record_file_sizes: ["benchmark", "file-size:*", "--results-file", "sizes.json"]
  upload_file_sizes: [bench-uploader.py, "sizes.json"]

  # These dummy artifacts are required by notify-releaser-build in order to trigger the releaser service
  # after the deploy jobs have completed.
  create_releaser_notifier_artifact: [
    ["python3", "-c", "from os import environ; open('../' + environ['BUILD_NAME'], 'a').close()"]
  ]

  deploy_graalvm_linux_amd64: {
    run: [
      ${mx_vm_installables} [graalvm-show]
      ${mx_vm_installables} [build]
      ${mx_vm_installables} ${maven_deploy_sdk_components}
      ${mx_vm_installables} ${record_file_sizes}
      ${upload_file_sizes}
    ] ${collect_profiles} [
      ${mx_vm_common} ${vm_profiles} [graalvm-show]
      ${mx_vm_common} ${vm_profiles} [build]
      ${mx_vm_common} ${vm_profiles} ${record_file_sizes}
      ${upload_file_sizes}
      ${mx_vm_common} ${vm_profiles} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
      [set-export, GRAALVM_HOME, ${mx_vm_common} [--quiet, --no-warning, graalvm-home]]
    ] ${create_releaser_notifier_artifact}
    logs: ${common_vm.logs}
    notify_emails: ["gilles.m.duboscq@oracle.com"]
    timelimit: "1:30:00"
  }

  deploy_graalvm_linux_aarch64: {
    run: [
      [set-export, VM_ENV, "${VM_ENV}-aarch64"]
      ${mx_vm_installables} [graalvm-show]
      ${mx_vm_installables} [build]
      ${mx_vm_installables} ${maven_deploy_sdk_components}
      ${mx_vm_installables} ${record_file_sizes}
      ${upload_file_sizes}
    ] ${collect_profiles} [
      ${mx_vm_common} ${vm_profiles} [graalvm-show]
      ${mx_vm_common} ${vm_profiles} [build]
      ${mx_vm_common} ${vm_profiles} ${record_file_sizes}
      ${upload_file_sizes}
      ${mx_vm_common} ${vm_profiles} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
    ] ${create_releaser_notifier_artifact}
    logs: ${common_vm.logs}
    notify_emails: ["gilles.m.duboscq@oracle.com"]
    timelimit: "1:30:00"
  }

  deploy_graalvm_base_darwin_amd64: {
    run: ${collect_profiles} [
      ${mx_vm_common} ${vm_profiles} [graalvm-show]
      ${mx_vm_common} ${vm_profiles} [build]
      ${mx_vm_common} ${vm_profiles} ${record_file_sizes}
      ${upload_file_sizes}
      ${mx_vm_common} ${vm_profiles} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
    ] ${create_releaser_notifier_artifact}
    notify_emails: ["gilles.m.duboscq@oracle.com"]
    timelimit: "1:45:00"
  }

  deploy_graalvm_installables_darwin_amd64: {
    run: [
      [set-export, VM_ENV, "${VM_ENV}-darwin"]
      ${mx_vm_installables} [graalvm-show]
      ${mx_vm_installables} [build]
      ${mx_vm_installables} ${maven_deploy_sdk_components}
      ${notify-nexus-deploy}
      ${mx_vm_installables} ${record_file_sizes}
      ${upload_file_sizes}
    ] ${create_releaser_notifier_artifact}
    notify_emails: ["gilles.m.duboscq@oracle.com"]
    timelimit: "3:00:00"
  }

  deploy_graalvm_base_windows_amd64: {
    run: [
      [set-export, VM_ENV, "${VM_ENV}-win"]
      ${mx_vm_common} [graalvm-show]
      ${mx_vm_common} [build]
      ${mx_vm_common} ${record_file_sizes}
      ${upload_file_sizes}
      ${mx_vm_common} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
    ] ${create_releaser_notifier_artifact}
    notify_emails: ["gilles.m.duboscq@oracle.com"]
    timelimit: "1:30:00"
  }

  deploy_graalvm_installables_windows_amd64: {
    run: [
      [set-export, VM_ENV, "${VM_ENV}-win"]
      ${mx_vm_installables} [graalvm-show]
      ${mx_vm_installables} [build]
      ${mx_vm_installables} ${maven_deploy_sdk_components}
      ${notify-nexus-deploy}
      ${mx_vm_installables} ${record_file_sizes}
      ${upload_file_sizes}
    ] ${create_releaser_notifier_artifact}
    notify_emails: ["gilles.m.duboscq@oracle.com"]
    timelimit: "1:30:00"
  }

  deploy_graalvm_ruby: {
    run: ${collect_profiles} [
      [set-export, VM_ENV, "${VM_ENV}-ruby"]
      ${mx_vm_common} ${vm_profiles} [graalvm-show]
      ${mx_vm_common} ${vm_profiles} [build]
      ${mx_vm_common} ${vm_profiles} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
      [set-export, GRAALVM_HOME, ${mx_vm_common} [--quiet, --no-warning, graalvm-home]]
    ] ${create_releaser_notifier_artifact}
    logs: ${common_vm.logs}
    notify_emails: ["benoit.daloze@oracle.com", "gilles.m.duboscq@oracle.com"]
    timelimit: "1:45:00"
  }

  #
  # Deploy GraalVM Base and Installables
  #

  # Linux/AMD64
  deploy-vm-java11-linux-amd64: ${vm_linux_amd64_java_11} ${full_vm_build_linux} ${linux-deploy} ${deploy_vm_linux} ${deploy_graalvm_linux_amd64} {name: deploy-vm-java11-linux-amd64}
  deploy-vm-java17-linux-amd64: ${vm_linux_amd64_java_17} ${full_vm_build_linux} ${linux-deploy} ${deploy_vm_linux} ${deploy_graalvm_linux_amd64} {name: deploy-vm-java17-linux-amd64}

  # Linux/AARCH64
  deploy-vm-java11-linux-aarch64: ${vm_java_11} ${full_vm_build_linux_aarch64} ${linux-deploy} ${deploy_daily_vm_linux_aarch64} ${deploy_graalvm_linux_aarch64} {name: deploy-vm-java11-linux-aarch64}
  deploy-vm-java17-linux-aarch64: ${vm_java_17} ${full_vm_build_linux_aarch64} ${linux-deploy} ${deploy_daily_vm_linux_aarch64} ${deploy_graalvm_linux_aarch64} {name: deploy-vm-java17-linux-aarch64}

  # Darwin/AMD64
  deploy-vm-base-java11-darwin-amd64: ${vm_java_11} ${full_vm_build_darwin} ${darwin-deploy} ${deploy_daily_vm_darwin} ${deploy_graalvm_base_darwin_amd64} {name: deploy-vm-base-java11-darwin-amd64}
  deploy-vm-installable-java11-darwin-amd64: ${vm_java_11} ${full_vm_build_darwin} ${darwin-deploy} ${deploy_daily_vm_darwin} ${deploy_graalvm_installables_darwin_amd64} {name: deploy-vm-installable-java11-darwin-amd64}
  deploy-vm-base-java17-darwin-amd64: ${vm_java_17} ${full_vm_build_darwin} ${darwin-deploy} ${deploy_daily_vm_darwin} ${deploy_graalvm_base_darwin_amd64} {name: deploy-vm-base-java17-darwin-amd64}
  deploy-vm-installable-java17-darwin-amd64: ${vm_java_17} ${full_vm_build_darwin} ${darwin-deploy} ${deploy_daily_vm_darwin} ${deploy_graalvm_installables_darwin_amd64} {name: deploy-vm-installable-java17-darwin-amd64}

  # Windows/AMD64
  deploy-vm-base-java11-windows-amd64: ${vm_java_11} ${svm-common-windows-jdk11} ${deploy_daily_vm_windows-jdk11} ${js_windows_jdk11} ${deploy_graalvm_base_windows_amd64} {name: deploy-vm-base-java11-windows-amd64}
  deploy-vm-installable-java11-windows-amd64: ${vm_java_11} ${svm-common-windows-jdk11} ${deploy_daily_vm_windows-jdk11} ${js_windows_jdk11} ${deploy_graalvm_installables_windows_amd64} {name: deploy-vm-installable-java11-windows-amd64}
  deploy-vm-base-java17-windows-amd64: ${vm_java_17} ${svm-common-windows-jdk17} ${deploy_daily_vm_windows-jdk17} ${js_windows_jdk17} ${deploy_graalvm_base_windows_amd64} {name: deploy-vm-base-java17-windows-amd64}
  deploy-vm-installable-java17-windows-amd64: ${vm_java_17} ${svm-common-windows-jdk17} ${deploy_daily_vm_windows-jdk17} ${js_windows_jdk17} ${deploy_graalvm_installables_windows_amd64} {name: deploy-vm-installable-java17-windows-amd64}

  #
  # Deploy the GraalVM Ruby image (GraalVM Base + ruby - js)
  #

  deploy-vm-ruby-java11-linux-amd64: ${vm_java_11} ${ruby_vm_build_linux} ${linux-deploy} ${deploy_daily_vm_linux} ${deploy_graalvm_ruby} {name: deploy-vm-ruby-java11-linux-amd64}
  deploy-vm-ruby-java11-darwin-amd64: ${vm_java_11} ${ruby_vm_build_darwin} ${darwin-deploy} ${deploy_daily_vm_darwin} ${deploy_graalvm_ruby} {name: deploy-vm-ruby-java11-darwin-amd64}

  #
  # Deploy GraalVM Complete
  #

  # Linux/AMD64
  deploy-vm-complete-java11-linux-amd64: ${vm_linux_amd64_java_11} ${full_vm_build_linux} ${linux-deploy} ${ondemand_vm_linux} {
    run: [
      ${mx_vm_installables} [graalvm-show]
      ${mx_vm_installables} [build]
      ${mx_vm_installables} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
    ]
    timelimit: "1:30:00"
    name: deploy-vm-complete-java11-linux-amd64
  }

  # Darwin/AMD64
  deploy-vm-complete-java11-darwin-amd64: ${vm_java_11} ${full_vm_build_darwin} ${darwin-deploy} ${ondemand_vm_darwin} {
    run: [
      ${mx_vm_installables} [graalvm-show]
      ${mx_vm_installables} [build]
      ${mx_vm_installables} ${maven_deploy_sdk_base}
      ${notify-nexus-deploy}
    ]
    timelimit: "2:30:00"
    name: deploy-vm-complete-java11-darwin-amd64
  }

  builds += [
    #
    # Gates
    #
    ${vm_java_17} ${eclipse} ${jdt} ${gate_vm_linux} {
      run: [
        [mx, gate, "-B=--force-deprecation-as-warning", --tags, "style,fullbuild"]
      ]
      name: gate-vm-style-jdk17-linux-amd64
    }
    ${libgraal_compiler} ${vm_java_11} { name: gate-vm-libgraal-compiler-11-linux-amd64 }
    ${libgraal_compiler} ${vm_java_17} { name: gate-vm-libgraal-compiler-17-linux-amd64 }

    ${libgraal_truffle} ${vm_java_11} ${vm_unittest} { name: gate-vm-libgraal-truffle-11-linux-amd64 }
    ${libgraal_truffle} ${vm_java_17} ${vm_unittest} { name: gate-vm-libgraal-truffle-17-linux-amd64 }

    ${vm_java_17} ${svm-common-linux-amd64} ${sulong_linux} ${custom_vm_linux} ${gate_vm_linux} ${vm_unittest} {
      run: [
        [export, "SVM_SUITE="${svm_suite}]
        [mx, --dynamicimports, "$SVM_SUITE,/sulong", --disable-polyglot, --disable-libpolyglot, gate, --no-warning-as-error, --tags, "build,sulong"]
      ]
      timelimit: "1:00:00"
      name: gate-vm-native-sulong
    }
  ]
}
{
  vm_java_8: ${openjdk8} {
    environment: {
      BASE_JDK_NAME: ${jdks.openjdk8.name}
      BASE_JDK_VERSION: ${jdks.openjdk8.version}
      BASE_JDK_SHORT_VERSION: "8"
    }
  }
  vm_java_11: ${labsjdk-ce-11} {
    environment: {
      BASE_JDK_NAME: ${jdks.labsjdk-ce-11.name}
      BASE_JDK_VERSION: ${jdks.labsjdk-ce-11.version}
      BASE_JDK_SHORT_VERSION: "11"
    }
  }
  vm_java_17: ${labsjdk-ce-17} {
    environment: {
      BASE_JDK_NAME: ${jdks.labsjdk-ce-17.name}
      BASE_JDK_VERSION: ${jdks.labsjdk-ce-17.version}
      BASE_JDK_SHORT_VERSION: "17"
    }
  }
  vm_common_windows_jdk8: ${svm-common-windows-openjdk8}

  vm_linux_amd64_java_11: ${vm_java_11} {
    downloads: {
      LLVM_JAVA_HOME: ${jdks.labsjdk-ce-11-llvm}
    }
  }

  vm_linux_amd64_java_17: ${vm_java_17} {
    downloads: {
      LLVM_JAVA_HOME: ${jdks.labsjdk-ce-17-llvm}
    }
  }

  svm_suite: /substratevm
  custom_vm_linux: {}
  custom_vm_darwin: {}
  vm_profiles: []
  collect_profiles: []

  vm_setup: {
    short_name: ce
    setup: [
      [set-export, VM_ENV, ce]
      [set-export, RELEASE_CATALOG, "{ee=GraalVM Enterprise Edition}gds://oca.opensource.oracle.com/gds/meta-data.json|https://www.graalvm.org/component-catalog/v2/graal-updater-component-catalog-java${BASE_JDK_SHORT_VERSION}.properties"]
      [set-export, SNAPSHOT_CATALOG, [mx, urlrewrite, "http://www.graalvm.org/catalog/ce/java${BASE_JDK_SHORT_VERSION}"]]
      [cd, ${vm_subdir}]
    ]
  }

  maven_base_8_11: {
    downloads: {
      JAVA_HOME: ${jdks.openjdk8},
      EXTRA_JAVA_HOMES: ${jdks.labsjdk-ce-11}
    }
    mx_cmd_base: [mx, --dynamicimports, "/tools,/compiler,/graal-js,/espresso", "--disable-installables=true"]
    build: ${maven_base_8_11.mx_cmd_base} [build]
    deploy: ${maven_base_8_11.mx_cmd_base} [--suite, compiler, --suite, truffle, --suite, sdk, --suite, tools, --suite, regex, --suite, graal-js, --suite, espresso, maven-deploy, "--tags=default", --all-distribution-types, --validate, full, --licenses, "GPLv2-CPE,UPL,MIT"]
  }

  maven_base_native: {
    native_distributions: "TRUFFLE_NFI_NATIVE,SVM_HOSTED_NATIVE"
    mx_cmd_base: [mx, --dynamicimports, "/substratevm", "--disable-installables=true", "--force-bash-launcher=true", "--skip-libraries=true"]
    build: ${maven_base_native.mx_cmd_base} [build, --dependencies, ${maven_base_native.native_distributions}]
    deploy: ${maven_base_native.mx_cmd_base} [maven-deploy, --only, ${maven_base_native.native_distributions}, "--tags=default", --all-suites, --all-distribution-types, --validate, full, --licenses, "GPLv2-CPE,UPL,MIT"]
  }

  maven_base_8_native: ${maven_base_native} {
    downloads: {
      JAVA_HOME: ${jdks.openjdk8},
    }
  }

  maven_base_11_native: ${maven_base_native} {
    downloads: {
      JAVA_HOME: ${jdks.labsjdk-ce-11},
    }
  }

  vm_unittest: {
    environment: {
        "MX_TEST_RESULTS_PATTERN": "es-XXX.json",
        "MX_TEST_RESULT_TAGS": "vm"
    }
  }

  notify-releaser-build: {
    name: notify-releaser-build
    packages: {
      curl: ">=7.50.1"
      git: ">=1.8.3"
    }
    setup: [
      [cd, ${vm_subdir}]
    ]
    run: [
      [
        [test, [git, rev-parse, --abbrev-ref, HEAD], "!=", master, "||"] ${notify-releaser-service}
      ]
    ]
    capabilities: [linux, amd64]
    requireArtifacts: [
      {name: deploy-vm-java11-linux-amd64}
      {name: deploy-vm-java17-linux-amd64}
      {name: deploy-vm-java11-linux-aarch64}
      {name: deploy-vm-java17-linux-aarch64}
      {name: deploy-vm-base-java11-darwin-amd64}
      {name: deploy-vm-installable-java11-darwin-amd64}
      {name: deploy-vm-base-java17-darwin-amd64}
      {name: deploy-vm-installable-java17-darwin-amd64}
      {name: deploy-vm-base-java11-windows-amd64}
      {name: deploy-vm-installable-java11-windows-amd64}
      {name: deploy-vm-base-java17-windows-amd64}
      {name: deploy-vm-installable-java17-windows-amd64}
      {name: deploy-vm-ruby-java11-linux-amd64}
      {name: deploy-vm-ruby-java11-darwin-amd64}
    ]
    targets: [daily]
  }

  builds += [
    ${vm_java_8} ${gate_vm_linux} ${vm_unittest} {
      run: [
        [mx, build]
        [mx, unittest, --suite, vm]
      ]
      name: gate-vm-unittest-linux-amd64
    }
    ${windows-amd64} ${oraclejdk8} ${devkits.windows-oraclejdk8} ${gate_vm_windows} ${vm_unittest} {
      run: [
          [mx, build]
          [mx, unittest, --suite, vm]
      ]
      name: gate-vm-unittest-windows
    }
    ${vm_java_11} ${gate_vm_linux} ${sulong_linux} {
      environment: {
        DYNAMIC_IMPORTS: "/tools,/substratevm,/sulong"
        NATIVE_IMAGES: "polyglot"
      }
      run: [
        [rm, "-rf", "../.git"]
        [mx, gate, "--strict-mode", "--tags", "build"]
      ]
      name: gate-vm-build-without-vcs
    }
    ${gate_vm_linux} ${linux-deploy} ${maven_base_8_11} ${sulong_linux} {
      run: [
        ${maven_base_8_11.build}
        ${maven_base_8_11.deploy} [--dry-run, "lafo-maven"]
      ]
      name: gate-vm-maven-dry-run-linux-amd64
    }
    ${gate_vm_linux} ${linux-deploy} ${maven_base_8_11} ${sulong_linux} {
      downloads+= {
        OPEN_JDK_11: ${jdks.openjdk11},
      }
      run: [
        ${maven_base_8_11.build}
        ${maven_base_8_11.deploy} ["--version-string", "GATE"]
        [set-export, JAVA_HOME, "$OPEN_JDK_11"]
        ["git", "clone", "--depth", "1", ["mx", "urlrewrite", "https://github.com/graalvm/graal-js-jdk11-maven-demo.git"], "graal-js-jdk11-maven-demo"]
        ["cd", "graal-js-jdk11-maven-demo"]
        ["mvn", "-Dgraalvm.version=GATE", "package"]
        ["mvn", "-Dgraalvm.version=GATE", "exec:exec"]
      ]
      name: gate-vm-js-on-jdk11-maven-linux-amd64
    }
    ${deploy_vm_linux} ${linux-deploy} ${maven_base_8_11} ${sulong_linux} {
      run: [
        ${maven_base_8_11.build}
        ${maven_base_8_11.deploy} ["lafo-maven"]
      ]
      name: deploy-vm-maven-linux-amd64
      timelimit: "45:00"
    }
    ${gate_vm_linux_aarch64} ${linux-deploy} ${maven_base_11_native} {
      run: [
        ${maven_base_11_native.build}
        ${maven_base_11_native.deploy} [--dry-run, "lafo-maven"]
      ]
      name: gate-vm-maven-dry-run-linux-aarch64
    }
    ${deploy_vm_linux_aarch64} ${linux-deploy} ${maven_base_11_native} {
      run: [
        ${maven_base_11_native.build}
        ${maven_base_11_native.deploy} ["lafo-maven"]
      ]
      name: deploy-vm-maven-linux-aarch64
    }
    ${gate_vm_darwin} ${darwin-deploy} ${maven_base_11_native} {
      run: [
        ${maven_base_11_native.build}
        ${maven_base_11_native.deploy} [--dry-run, "lafo-maven"]
      ]
      name: gate-vm-maven-dry-run-darwin-amd64
    }
    ${deploy_daily_vm_darwin} ${darwin-deploy} ${maven_base_11_native} {
      run: [
        ${maven_base_11_native.build}
        ${maven_base_11_native.deploy} ["lafo-maven"]
      ]
      name: deploy-vm-maven-darwin-amd64
    }
    ${vm_common_windows_jdk8} ${gate_vm_windows} ${maven_base_8_native} {
      run: [
        ${maven_base_8_native.build}
        ${maven_base_8_native.deploy} [--dry-run, "lafo-maven"]
      ]
      name: gate-vm-maven-dry-run-windows-amd64
    }
    ${vm_common_windows_jdk8} ${deploy_daily_vm_windows} ${maven_base_8_native} {
      run: [
        ${maven_base_8_native.build}
        ${maven_base_8_native.deploy} ["lafo-maven"]
      ]
      name: deploy-vm-maven-windows-amd64
    }

    #
    # Deploy GraalVM Base and Installables
    #

    # Linux/AMD64
    ${deploy-vm-java11-linux-amd64} {publishArtifacts: [{name: deploy-vm-java11-linux-amd64, patterns: [deploy-vm-java11-linux-amd64]}]}
    ${deploy-vm-java17-linux-amd64} {publishArtifacts: [{name: deploy-vm-java17-linux-amd64, patterns: [deploy-vm-java17-linux-amd64]}]}

    # Linux/AARCH64
    ${deploy-vm-java11-linux-aarch64} {publishArtifacts: [{name: deploy-vm-java11-linux-aarch64, patterns: [deploy-vm-java11-linux-aarch64]}]}
    ${deploy-vm-java17-linux-aarch64} {publishArtifacts: [{name: deploy-vm-java17-linux-aarch64, patterns: [deploy-vm-java17-linux-aarch64]}]}

    # Darwin/AMD64
    ${deploy-vm-base-java11-darwin-amd64} {publishArtifacts: [{name: deploy-vm-base-java11-darwin-amd64, patterns: [deploy-vm-base-java11-darwin-amd64]}]}
    ${deploy-vm-installable-java11-darwin-amd64} {publishArtifacts: [{name: deploy-vm-installable-java11-darwin-amd64, patterns: [deploy-vm-installable-java11-darwin-amd64]}]}
    ${deploy-vm-base-java17-darwin-amd64} {publishArtifacts: [{name: deploy-vm-base-java17-darwin-amd64, patterns: [deploy-vm-base-java17-darwin-amd64]}]}
    ${deploy-vm-installable-java17-darwin-amd64} {publishArtifacts: [{name: deploy-vm-installable-java17-darwin-amd64, patterns: [deploy-vm-installable-java17-darwin-amd64]}]}

    # Windows/AMD64
    ${deploy-vm-base-java11-windows-amd64} {publishArtifacts: [{name: deploy-vm-base-java11-windows-amd64, patterns: [deploy-vm-base-java11-windows-amd64]}]}
    ${deploy-vm-installable-java11-windows-amd64} {publishArtifacts: [{name: deploy-vm-installable-java11-windows-amd64, patterns: [deploy-vm-installable-java11-windows-amd64]}]}
    ${deploy-vm-base-java17-windows-amd64} {publishArtifacts: [{name: deploy-vm-base-java17-windows-amd64, patterns: [deploy-vm-base-java17-windows-amd64]}]}
    ${deploy-vm-installable-java17-windows-amd64} {publishArtifacts: [{name: deploy-vm-installable-java17-windows-amd64, patterns: [deploy-vm-installable-java17-windows-amd64]}]}

    #
    # Deploy the GraalVM Ruby image (GraalVM Base + ruby - js)
    #
    ${deploy-vm-ruby-java11-linux-amd64} {publishArtifacts: [{name: deploy-vm-ruby-java11-linux-amd64, patterns: [deploy-vm-ruby-java11-linux-amd64]}]}
    ${deploy-vm-ruby-java11-darwin-amd64} {publishArtifacts: [{name: deploy-vm-ruby-java11-darwin-amd64, patterns: [deploy-vm-ruby-java11-darwin-amd64]}]}

    #
    # Deploy GraalVM Complete
    #
    ${deploy-vm-complete-java11-linux-amd64}
    ${deploy-vm-complete-java11-darwin-amd64}

    # Trigger the releaser service
    ${notify-releaser-build}
  ]
}
Pod::Spec.new do |s|
  s.name             = 'SwiftProjection'
  s.version          = '1.0.4'
  s.summary          = 'Easy map projections in Swift'
  s.description      = <<-DESC
SwiftProjection is a framework for performing map projections and transformations in Swift using the PROJ library.
                       DESC

  s.homepage         = 'https://github.com/paxswill/SwiftProjection'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Will Ross' => 'paxswill@paxswill.com' }
  s.source           = { :git => 'https://github.com/paxswill/SwiftProjection.git',
                         :tag => "v#{s.version.to_s}",
                         :submodules => true }
  s.cocoapods_version = '>= 1.5.0.beta.1'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.swift_version = '4.1'

  s.compiler_flags = [
    '-DMUTEX_pthread',
  ]
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/proj-src/src/"',
    # the upstream PROJ source has s single 'prototype' that isn't really a
    # prototype in a public header file.
    'OTHER_CFLAGS' => '-Wno-strict-prototypes -Wno-documentation -Wno-comma -Wno-shorten-64-to-32 -Wno-#warnings',
  }

  s.module_name = 'SwiftProjection'
  s.source_files = [
    'Classes/*',
    'proj-src/src/pj_*.{h,c}', 'proj-src/src/PJ_*.{h,c}',
    'proj-src/src/proj_*.{h,c}', 'proj-src/src/proj.h',
    'proj-src/src/projects.h',
    'proj-src/src/aasincos.c', 'proj-src/src/adjlon.c',
    'proj-src/src/bch2bps.c', 'proj-src/src/bchgen.c',
    'proj-src/src/dmstor.c', 'proj-src/src/rtodms.c',
    'proj-src/src/mk_cheby.c', 'proj-src/src/vector1.c',
    'proj-src/src/biveval.c',
    'proj-src/src/nad_*', 'proj-src/src/emess.{h,c}',
    'proj-src/src/geocent.{h,c}', 'proj-src/src/geodesic.{h,c}',
  ]
  s.public_header_files = [
    'proj-src/src/proj.h',
    'proj-src/src/proj_api.h',
    'Classes/bundle-reader.h',
  ]
  s.private_header_files = [
    'proj-src/src/projects.h',
    'proj-src/src/proj_internal.h',
  ]
  s.resource_bundles = {
    'proj-data' => [
      'proj-src/nad/*',
      # If a plain wildcard is used, everything is included, including
      # subdirectories. So instead each file is listed specifically
      'proj-datumgrid/alaska', 'proj-datumgrid/BETA2007.gsb',
      'proj-datumgrid/conus', 'proj-datumgrid/egm96_15.gtx',
      'proj-datumgrid/FL', 'proj-datumgrid/hawaii',
      'proj-datumgrid/MD', 'proj-datumgrid/ntf_r93.gsb',
      'proj-datumgrid/ntv1_can.dat', 'proj-datumgrid/null',
      'proj-datumgrid/nzgd2kgrid0005.gsb', 'proj-datumgrid/prvi',
      'proj-datumgrid/stgeorge', 'proj-datumgrid/stlrnc ',
      'proj-datumgrid/stpaul', 'proj-datumgrid/TN', 'proj-datumgrid/WI',
      'proj-datumgrid/WO',
    ]
  }
  s.exclude_files = [
    '**/*.in', '**/*.am', '**/CMakeLists.txt',
    'proj-src/**/README',
    'proj-src/nad/test*', 'proj-src/nad/*.dist*', 'proj-src/nad/*.lla',
  ]

  s.libraries = 'pthread'
  s.dependency 'Threadly', '~> 2.0.1'

  s.test_spec 'Tests' do |t|
    t.source_files = 'Tests/*'
    t.dependency 'Quick', '~> 1.2.0'
    t.dependency 'Nimble', '~> 7.0.2'
  end
end

project('com.github.donadigo.appeditor', ['vala', 'c'],
        version: '1.1.1')

i18n = import('i18n')
gnome = import('gnome')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h'
]

vala = meson.get_compiler('vala')
vala_flags = []

deps = [
  dependency('granite'),
  dependency('gtk+-3.0'),
  dependency('gee-0.8'),
  vala.find_library('posix')
]

if vala.version().version_compare('>= 0.40.0')
    vala_flags += ['--define', 'HAS_VALA040']
endif

if get_option('flatpak')
  add_project_arguments('--define=FLATPAK', language: 'vala')
endif

add_project_arguments(vala_flags, language: 'vala')

asresources = gnome.compile_resources(
    'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/AppSourceList.vala',
    'src/AppItem.vala',
    'src/CategoryItem.vala',
    'src/IconButton.vala',
    'src/SettingBox.vala',
    'src/PersistentPlaceholderEntry.vala',
    'src/FieldEntry.vala',
    'src/CategoryComboBox.vala',
    'src/AppInfoViewStack.vala',
    'src/AppInfoView.vala',
    'src/AppDirectoryScanner.vala',
    'src/DesktopApp.vala',
    'src/DesktopAppManager.vala',
    'src/AppInfoViewSaver.vala',
    'src/IconListBox.vala',
    'src/IconChooserDialog.vala',
    'src/IconRow.vala',
    'src/Constants.vala',
    asresources,
    c_args: c_args,
    dependencies: [
        deps
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
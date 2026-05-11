project = 'Little Guy'
copyright = '2026, Team1C-T-P'
author = 'Team1C-T-P'
release = '0.3.1'

extensions = [
    'myst_parser',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

html_theme = 'furo'
html_static_path = ['_static']

html_theme_options = {
    "sidebar_hide_name": False,
}

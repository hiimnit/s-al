controladdin "FS Monaco Editor"
{
    MinimumHeight = 750;
    MaximumHeight = 1080;
    MinimumWidth = 750;
    MaximumWidth = 1920;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;
    Scripts = 'src/Editor/js/chunk.js', 'src/Editor/js/main.chunk.js', 'src/Editor/js/runtime-main.js';
    StyleSheets = 'src/Editor/css/main.chunk.css';
    StartupScript = 'src/Editor/js/startup.js';

    event Execute(Code: Text);
    event Compile(Code: Text);
    event Analyze(Code: Text);
}
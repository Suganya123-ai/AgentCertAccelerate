% =========================================================
% ARIA — Production Class
% =========================================================
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{infosys-design}[2025/12/24 ARIA class]

% ---------------------------------------------------------
% Base class: KOMA-Script book
% ---------------------------------------------------------
\LoadClass[
  11pt,
  openany,
  twoside
]{scrbook}

% ---------------------------------------------------------
% Engine check
% ---------------------------------------------------------
\RequirePackage{iftex}
\ifPDFTeX
  \ClassError{infosys-design}
    {LuaLaTeX or XeLaTeX required}
    {Use lualatex or xelatex}
\fi

% ---------------------------------------------------------
% Core packages
% ---------------------------------------------------------
\RequirePackage{xcolor}
\RequirePackage{graphicx}
\RequirePackage{geometry}
\RequirePackage{fontspec}
\RequirePackage{microtype}
\RequirePackage{setspace}
\RequirePackage{tikz}
\RequirePackage{scrlayer-scrpage}
\RequirePackage{multicol}
\RequirePackage{caption}
\RequirePackage[hidelinks]{hyperref}
% ---------------------------------------------------------
% Geometry
% ---------------------------------------------------------
\geometry{
  a4paper,
  top=22mm,
  bottom=18mm,
  inner=20mm,
  outer=16mm
}

% ---------------------------------------------------------
% Color system
% ---------------------------------------------------------
\definecolor{TN-Navy}{HTML}{0B1F3A}
\definecolor{TN-Gray}{HTML}{6F7782}
\definecolor{TN-Blue}{HTML}{1A82C7}
\definecolor{TN-CalloutBG}{HTML}{F4F7FA}

% ---------------------------------------------------------
% Typography
% ---------------------------------------------------------
\defaultfontfeatures{Ligatures=TeX}
\setmainfont[
  Path=./fonts/,
  UprightFont=MyriadPro-Regular.otf,
  BoldFont=MyriadPro-Bold.otf,
  ItalicFont=MyriadPro-It.otf,
  BoldItalicFont=MyriadPro-BoldIt.otf,
  SmallCapsFont=MyriadPro-Semibold.otf
]{Myriad Pro}

\newfontfamily\myriadcondensed[
  Path = fonts/,
  UprightFont = MyriadPro-Cond.otf,
  BoldFont    = MyriadPro-BoldCond.otf
]{Myriad Pro Condensed}

\setstretch{1.12}

% ---------------------------------------------------------
% Headers / Footers
% ---------------------------------------------------------
\clearpairofpagestyles
\pagestyle{scrheadings}

% Use scrheadings style on chapter pages too
\renewcommand*{\chapterpagestyle}{scrheadings}

\newcommand{\TNBrand}{Your Brand | Knowledge Institute}
\newcommand{\TNTitle}{ARIA: Enterprise Agentic AI Blueprint}
\newcommand{\TNDocTag}{External Document © 2025 Your Company}

\ihead{\color{TN-Gray}\fontsize{9}{10}\selectfont \TNBrand}
\ifoot{\color{TN-Gray}\fontsize{8}{9}\selectfont \TNDocTag}
\ofoot{\color{TN-Gray}\fontsize{8}{9}\selectfont \TNTitle\;\textbar\;\thepage}

% Redefine plain style to have the same footer
\defpagestyle{plain}{%
  {\hfill}{\hfill}{\hfill}%
}{%
  {\color{TN-Gray}\fontsize{8}{9}\selectfont \TNDocTag}%
  {\hfill}%
  {\color{TN-Gray}\fontsize{8}{9}\selectfont \TNTitle\;\textbar\;\thepage}%
}

% --------------------------------------------------
% STRUCTURE: Part / Chapter / Section
% --------------------------------------------------

% Enable numbered parts and chapters
\setcounter{secnumdepth}{3}
\setcounter{tocdepth}{3}

% ---------------------------------------------------------
% Headings (KOMA-native)
% ---------------------------------------------------------
\addtokomafont{part}{\color{TN-Navy}\Huge\bfseries}
\renewcommand*{\partformat}{Part~\thepart\autodot\enskip}
\RedeclareSectionCommand[
  beforeskip=2\baselineskip,
  afterskip=1.5\baselineskip,
  toclevel=0,
  style=section
]{part}
\addtokomafont{chapter}{\color{TN-Navy}\bfseries\fontsize{26}{32}\selectfont}
\addtokomafont{chapterprefix}{\Large}
\addtokomafont{chapterentry}{\bfseries}
\addtokomafont{section}{\color{TN-Navy}\bfseries\large}
\RedeclareSectionCommand[beforeskip=1.2\baselineskip,afterskip=0.8\baselineskip]{section}
\addtokomafont{subsection}{\color{TN-Navy}\bfseries\fontsize{12}{15}\selectfont}

\RedeclareSectionCommand[
  beforeskip=10mm,
  afterskip=6mm
]{chapter}

% ---------------------------------------------------------
% Two-column editorial body
% ---------------------------------------------------------
\setlength{\columnsep}{10mm}
\newenvironment{TNtwocol}{\begin{multicols}{2}}{\end{multicols}}

% ---------------------------------------------------------
% Chapter helper (NO page forcing!)
% ---------------------------------------------------------
\newcommand{\TNrule}{\par\noindent\rule{\linewidth}{0.5pt}\par}

\newcommand{\TNchapter}[2][]{%
  \chapter{#2}
  \if\relax\detokenize{#1}\relax\else
    \vspace{6mm}
    {\color{TN-Gray}\fontsize{12}{17}\selectfont #1\par}
    \vspace{6mm}
    \TNrule
    \vspace{8mm}
  \fi
}

% ---------------------------------------------------------
% Cover + TOC assets
% ---------------------------------------------------------
\newcommand{\TNCoverImage}{assets/cover.png}
\newcommand{\TNLogoImage}{assets/logo.png}
\newcommand{\TNTOCHeroImage}{assets/toc-hero.png}

\newcommand{\TNCoverKicker}{INFOYS DESIGN}
\newcommand{\TNCoverTitleA}{INFOSYS BOOK TITLE B}
\newcommand{\TNCoverTitleB}{INFOSYS BOOK TITLE B}

% ---------------------------------------------------------
% Full-bleed background helper
% ---------------------------------------------------------
\newcommand{\TNFullBleedBackground}[1]{%
  \AddToHookNext{shipout/background}{%
    \begin{tikzpicture}[remember picture,overlay]
      \node at (current page.center) {%
        \includegraphics[width=\paperwidth,height=\paperheight]{#1}};
    \end{tikzpicture}
  }%
}

% ---------------------------------------------------------
% Cover page
% ---------------------------------------------------------
\newcommand{\MakeCover}{%
  \cleardoublepage
  \thispagestyle{empty}

  \TNFullBleedBackground{\TNCoverImage}

  \begin{tikzpicture}[remember picture,overlay]
    % Logo
    \node[anchor=north east,xshift=-16mm,yshift=-16mm]
      at (current page.north east)
      {\includegraphics[height=12mm]{\TNLogoImage}};

    % Text block
    \node[anchor=west,xshift=20mm,yshift=-80mm]
      at (current page.north west)
      {%
        \begin{minipage}{0.6\paperwidth}
          {\color{white}\fontsize{12}{14}\selectfont \TNCoverKicker\par}
          \vspace{6mm}
          {\color{white}\bfseries\fontsize{36}{40}\selectfont \TNCoverTitleA\par}
          \vspace{3mm}
          {\color{white}\bfseries\fontsize{36}{40}\selectfont \TNCoverTitleB\par}
        \end{minipage}
      };
  \end{tikzpicture}

  \clearpage
}


% ---------------------------------------------------------
% TOC Styling
% ---------------------------------------------------------
% Dotted leader style (must be defined first)


% Customize chapter entries in TOC with dotted leaders
\DeclareTOCStyleEntry[
  entryformat=\normalfont\normalsize,
  pagenumberformat=\normalfont\normalsize,
  linefill=\TOCLineLeaderFill,
  beforeskip=.8em plus 1pt,
  raggedentrytext=false
]{tocline}{chapter}

% ---------------------------------------------------------
% Contents (single, correct, KOMA-safe)
% ---------------------------------------------------------
\newcommand{\MakeContents}{%
  \cleardoublepage
  \thispagestyle{scrheadings}

  \IfFileExists{\TNTOCHeroImage}{%
    \includegraphics[width=\textwidth]{\TNTOCHeroImage}\par\vspace{8mm}
  }{}

  {\myriadcondensed\bfseries\fontsize{28}{32}\selectfont CONTENTS\par}
  \vspace{6mm}

  \begingroup
    \let\chapter\relax
    \listoftoc*{toc}
  \endgroup
  
}

% ---------------------------------------------------------
% End class
% ---------------------------------------------------------
\endinput

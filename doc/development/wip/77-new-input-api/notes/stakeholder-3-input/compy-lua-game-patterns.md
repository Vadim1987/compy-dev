<!DOCTYPE html>
<html lang="en-US" data-theme="gitea-auto">
<head>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>compy-project/dev/docs/compy-lua-game-patterns.md at main - compy-project - git for baldvin.net</title>
	<link rel="manifest" href="data:application/json;base64,eyJuYW1lIjoiZ2l0IGZvciBiYWxkdmluLm5ldCIsInNob3J0X25hbWUiOiJnaXQgZm9yIGJhbGR2aW4ubmV0Iiwic3RhcnRfdXJsIjoiaHR0cHM6Ly9naXQuYmFsZHZpbi5uZXQvIiwiaWNvbnMiOlt7InNyYyI6Imh0dHBzOi8vZ2l0LmJhbGR2aW4ubmV0L2Fzc2V0cy9pbWcvbG9nby5wbmciLCJ0eXBlIjoiaW1hZ2UvcG5nIiwic2l6ZXMiOiI1MTJ4NTEyIn0seyJzcmMiOiJodHRwczovL2dpdC5iYWxkdmluLm5ldC9hc3NldHMvaW1nL2xvZ28uc3ZnIiwidHlwZSI6ImltYWdlL3N2Zyt4bWwiLCJzaXplcyI6IjUxMng1MTIifV19">
	<meta name="author" content="educationmatters">
	<meta name="description" content="compy-project - Scaffolding and coordination layer for the Compy project under Education Matters umbrella.">
	<meta name="keywords" content="go,git,self-hosted,gitea">
	<meta name="referrer" content="no-referrer">


	<link rel="alternate" type="application/atom+xml" title="" href="/educationmatters/compy-project.atom">
	<link rel="alternate" type="application/rss+xml" title="" href="/educationmatters/compy-project.rss">

	<link rel="icon" href="/assets/img/favicon.svg" type="image/svg+xml">
	<link rel="alternate icon" href="/assets/img/favicon.png" type="image/png">
	
	
		<meta property="og:title" content="compy-project/dev/docs/compy-lua-game-patterns.md at main">
		<meta property="og:url" content="https://git.baldvin.net//educationmatters/compy-project/src/branch/main/dev/docs/compy-lua-game-patterns.md">
		
	
	<meta property="og:type" content="object">
	
		<meta property="og:image" content="https://git.baldvin.net/avatars/6536ffb40ff08af8575e5c834bb91d2d">
	

<meta property="og:site_name" content="git for baldvin.net">

	<link rel="stylesheet" href="/assets/css/index.css?v=1.25.4">
<link rel="stylesheet" href="/assets/css/theme-gitea-auto.css?v=1.25.4">

	
<script>
	
	window.addEventListener('error', function(e) {window._globalHandlerErrors=window._globalHandlerErrors||[]; window._globalHandlerErrors.push(e);});
	window.addEventListener('unhandledrejection', function(e) {window._globalHandlerErrors=window._globalHandlerErrors||[]; window._globalHandlerErrors.push(e);});
	window.config = {
		appUrl: 'https:\/\/git.baldvin.net\/',
		appSubUrl: '',
		assetVersionEncoded: encodeURIComponent('1.25.4'), 
		assetUrlPrefix: '\/assets',
		runModeIsProd:  true ,
		customEmojis: {"codeberg":":codeberg:","git":":git:","gitea":":gitea:","github":":github:","gitlab":":gitlab:","gogs":":gogs:"},
		csrfToken: '0BiRZiPCn86chG2ED9ihFUdxxzA6MTc4MjE0NTk5NDAwNzA5Njg2MQ',
		pageData: {},
		notificationSettings: {"EventSourceUpdateTime":10000,"MaxTimeout":60000,"MinTimeout":10000,"TimeoutStep":10000}, 
		enableTimeTracking:  true ,
		
		mermaidMaxSourceCharacters:  50000 ,
		
		i18n: {
			copy_success: "Copied!",
			copy_error: "Copy failed",
			error_occurred: "An error occurred",
			remove_label_str: "Remove item \"%s\"",
			modal_confirm: "Confirm",
			modal_cancel: "Cancel",
			more_items: "More items",
		},
	};
	
	window.config.pageData = window.config.pageData || {};
</script>
<script src="/assets/js/index.js?v=1.25.4" onerror="alert('Failed to load asset files from ' + this.src + '. Please make sure the asset files can be accessed.')"></script>

	
</head>
<body hx-headers='{"x-csrf-token": "0BiRZiPCn86chG2ED9ihFUdxxzA6MTc4MjE0NTk5NDAwNzA5Njg2MQ"}' hx-swap="outerHTML" hx-ext="morph" hx-push-url="false">
	

	<div class="full height">
		<noscript>This website requires JavaScript.</noscript>

		

		
			<nav id="navbar" aria-label="Navigation Bar">
	<div class="navbar-left">
		
		<a class="item" id="navbar-logo" href="/" aria-label="Dashboard">
			<img width="30" height="30" src="/assets/img/logo.svg" alt="Logo" aria-hidden="true">
		</a>

		
		<div class="ui secondary menu navbar-mobile-right only-mobile">
			
	<a class="item " href="/notifications" data-tooltip-content="Notifications">
		<div class="tw-relative">
			<svg viewBox="0 0 16 16" class="svg octicon-bell" aria-hidden="true" width="16" height="16"><path d="M8 16a2 2 0 0 0 1.985-1.75c.017-.137-.097-.25-.235-.25h-3.5c-.138 0-.252.113-.235.25A2 2 0 0 0 8 16M3 5a5 5 0 0 1 10 0v2.947q0 .076.042.139l1.703 2.555A1.519 1.519 0 0 1 13.482 13H2.518a1.516 1.516 0 0 1-1.263-2.36l1.703-2.554A.26.26 0 0 0 3 7.947Zm5-3.5A3.5 3.5 0 0 0 4.5 5v2.947c0 .346-.102.683-.294.97l-1.703 2.556-.003.01.001.006q0 .003.004.006l.006.004.007.001h10.964l.007-.001.006-.004.004-.006.001-.007-.003-.01-1.703-2.554a1.75 1.75 0 0 1-.294-.97V5A3.5 3.5 0 0 0 8 1.5"/></svg>
			<span class="notification_count">3</span>
		</div>
	</a>
	


			<button class="item ui icon mini button tw-m-0" id="navbar-expand-toggle" aria-label="Navigation Menu"><svg viewBox="0 0 16 16" class="svg octicon-three-bars" aria-hidden="true" width="16" height="16"><path d="M1 2.75A.75.75 0 0 1 1.75 2h12.5a.75.75 0 0 1 0 1.5H1.75A.75.75 0 0 1 1 2.75m0 5A.75.75 0 0 1 1.75 7h12.5a.75.75 0 0 1 0 1.5H1.75A.75.75 0 0 1 1 7.75M1.75 12h12.5a.75.75 0 0 1 0 1.5H1.75a.75.75 0 0 1 0-1.5"/></svg></button>
		</div>

		
		
			
				<a class="item" href="/issues">Issues</a>
			
			
				<a class="item" href="/pulls">Pull Requests</a>
			
			
				
					<a class="item" href="/milestones">Milestones</a>
				
			
			<a class="item" href="/explore/repos">Explore</a>
		

		

		
	</div>

	
	<div class="navbar-right">
		
			
	<a class="item not-mobile" href="/notifications" data-tooltip-content="Notifications">
		<div class="tw-relative">
			<svg viewBox="0 0 16 16" class="svg octicon-bell" aria-hidden="true" width="16" height="16"><path d="M8 16a2 2 0 0 0 1.985-1.75c.017-.137-.097-.25-.235-.25h-3.5c-.138 0-.252.113-.235.25A2 2 0 0 0 8 16M3 5a5 5 0 0 1 10 0v2.947q0 .076.042.139l1.703 2.555A1.519 1.519 0 0 1 13.482 13H2.518a1.516 1.516 0 0 1-1.263-2.36l1.703-2.554A.26.26 0 0 0 3 7.947Zm5-3.5A3.5 3.5 0 0 0 4.5 5v2.947c0 .346-.102.683-.294.97l-1.703 2.556-.003.01.001.006q0 .003.004.006l.006.004.007.001h10.964l.007-.001.006-.004.004-.006.001-.007-.003-.01-1.703-2.554a1.75 1.75 0 0 1-.294-.97V5A3.5 3.5 0 0 0 8 1.5"/></svg>
			<span class="notification_count">3</span>
		</div>
	</a>
	


			<div class="ui dropdown jump item" data-tooltip-content="Create…">
				<span class="text">
					<svg viewBox="0 0 16 16" class="svg octicon-plus" aria-hidden="true" width="16" height="16"><path d="M7.75 2a.75.75 0 0 1 .75.75V7h4.25a.75.75 0 0 1 0 1.5H8.5v4.25a.75.75 0 0 1-1.5 0V8.5H2.75a.75.75 0 0 1 0-1.5H7V2.75A.75.75 0 0 1 7.75 2"/></svg>
					<span class="not-mobile"><svg viewBox="0 0 16 16" class="svg octicon-triangle-down" aria-hidden="true" width="16" height="16"><path d="m4.427 7.427 3.396 3.396a.25.25 0 0 0 .354 0l3.396-3.396A.25.25 0 0 0 11.396 7H4.604a.25.25 0 0 0-.177.427"/></svg></span>
					<span class="only-mobile">Create…</span>
				</span>
				<div class="menu">
					<a class="item" href="/repo/create">
						<svg viewBox="0 0 16 16" class="svg octicon-plus" aria-hidden="true" width="16" height="16"><path d="M7.75 2a.75.75 0 0 1 .75.75V7h4.25a.75.75 0 0 1 0 1.5H8.5v4.25a.75.75 0 0 1-1.5 0V8.5H2.75a.75.75 0 0 1 0-1.5H7V2.75A.75.75 0 0 1 7.75 2"/></svg> New Repository
					</a>
					
						<a class="item" href="/repo/migrate">
							<svg viewBox="0 0 16 16" class="svg octicon-repo-push" aria-hidden="true" width="16" height="16"><path d="M2 2.5A2.5 2.5 0 0 1 4.5 0h8.75a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0V1.5h-8a1 1 0 0 0-1 1v6.708A2.5 2.5 0 0 1 4.5 9h2.25a.75.75 0 0 1 0 1.5H4.5a1 1 0 0 0 0 2h4.75a.75.75 0 0 1 0 1.5H4.5A2.5 2.5 0 0 1 2 11.5Zm12.23 7.79zl-1.224-1.224v6.184a.75.75 0 0 1-1.5 0V9.066L10.28 10.29a.75.75 0 0 1-1.06-1.061l2.505-2.504a.75.75 0 0 1 1.06 0L15.29 9.23a.75.75 0 0 1-.018 1.042.75.75 0 0 1-1.042.018"/></svg> New Migration
						</a>
					
					
				</div>
			</div>

			<div class="ui dropdown jump item" data-tooltip-content="Profile and Settings…">
				<span class="text">
					<img loading="lazy" alt class="ui avatar tw-align-middle tw-mr-1" src="/avatars/d449a3efeb7ba3f17619a6e39ea71a10?size=48" title="Hleb R" width="24" height="24"/>
					<span class="only-mobile">hleb</span>
					<span class="not-mobile"><svg viewBox="0 0 16 16" class="svg octicon-triangle-down" aria-hidden="true" width="16" height="16"><path d="m4.427 7.427 3.396 3.396a.25.25 0 0 0 .354 0l3.396-3.396A.25.25 0 0 0 11.396 7H4.604a.25.25 0 0 0-.177.427"/></svg></span>
				</span>
				<div class="menu user-menu">
					<div class="header">
						Signed in as <strong>hleb</strong>
					</div>

					<div class="divider"></div>
					<a class="item" href="/hleb">
						<svg viewBox="0 0 16 16" class="svg octicon-person" aria-hidden="true" width="16" height="16"><path d="M10.561 8.073a6 6 0 0 1 3.432 5.142.75.75 0 1 1-1.498.07 4.5 4.5 0 0 0-8.99 0 .75.75 0 0 1-1.498-.07 6 6 0 0 1 3.431-5.142 3.999 3.999 0 1 1 5.123 0M10.5 5a2.5 2.5 0 1 0-5 0 2.5 2.5 0 0 0 5 0"/></svg>
						Profile
					</a>
					
						<a class="item" href="/hleb?tab=stars">
							<svg viewBox="0 0 16 16" class="svg octicon-star" aria-hidden="true" width="16" height="16"><path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.751.751 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25m0 2.445L6.615 5.5a.75.75 0 0 1-.564.41l-3.097.45 2.24 2.184a.75.75 0 0 1 .216.664l-.528 3.084 2.769-1.456a.75.75 0 0 1 .698 0l2.77 1.456-.53-3.084a.75.75 0 0 1 .216-.664l2.24-2.183-3.096-.45a.75.75 0 0 1-.564-.41z"/></svg>
							Starred
						</a>
					
					<a class="item" href="/notifications/subscriptions">
						<svg viewBox="0 0 16 16" class="svg octicon-bell" aria-hidden="true" width="16" height="16"><path d="M8 16a2 2 0 0 0 1.985-1.75c.017-.137-.097-.25-.235-.25h-3.5c-.138 0-.252.113-.235.25A2 2 0 0 0 8 16M3 5a5 5 0 0 1 10 0v2.947q0 .076.042.139l1.703 2.555A1.519 1.519 0 0 1 13.482 13H2.518a1.516 1.516 0 0 1-1.263-2.36l1.703-2.554A.26.26 0 0 0 3 7.947Zm5-3.5A3.5 3.5 0 0 0 4.5 5v2.947c0 .346-.102.683-.294.97l-1.703 2.556-.003.01.001.006q0 .003.004.006l.006.004.007.001h10.964l.007-.001.006-.004.004-.006.001-.007-.003-.01-1.703-2.554a1.75 1.75 0 0 1-.294-.97V5A3.5 3.5 0 0 0 8 1.5"/></svg>
						Subscriptions
					</a>
					<a class="item" href="/user/settings">
						<svg viewBox="0 0 16 16" class="svg octicon-tools" aria-hidden="true" width="16" height="16"><path d="M5.433 2.304A4.49 4.49 0 0 0 3.5 6c0 1.598.832 3.002 2.09 3.802.518.328.929.923.902 1.64v.008l-.164 3.337a.75.75 0 1 1-1.498-.073l.163-3.33c.002-.085-.05-.216-.207-.316A6 6 0 0 1 2 6a6 6 0 0 1 2.567-4.92 1.48 1.48 0 0 1 1.673-.04c.462.296.76.827.76 1.423v2.82c0 .082.041.16.11.206l.75.51a.25.25 0 0 0 .28 0l.75-.51A.25.25 0 0 0 9 5.282V2.463c0-.596.298-1.127.76-1.423a1.48 1.48 0 0 1 1.673.04A6 6 0 0 1 14 6a6 6 0 0 1-2.786 5.068c-.157.1-.209.23-.207.315l.163 3.33a.752.752 0 0 1-1.094.714.75.75 0 0 1-.404-.64l-.164-3.345c-.027-.717.384-1.312.902-1.64A4.5 4.5 0 0 0 12.5 6a4.49 4.49 0 0 0-1.933-3.696c-.024.017-.067.067-.067.16v2.818a1.75 1.75 0 0 1-.767 1.448l-.75.51a1.75 1.75 0 0 1-1.966 0l-.75-.51A1.75 1.75 0 0 1 5.5 5.282V2.463c0-.092-.043-.142-.067-.159"/></svg>
						Settings
					</a>
					<a class="item" target="_blank" rel="noopener noreferrer" href="https://docs.gitea.com">
						<svg viewBox="0 0 16 16" class="svg octicon-question" aria-hidden="true" width="16" height="16"><path d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8m8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13M6.92 6.085h.001a.749.749 0 1 1-1.342-.67c.169-.339.436-.701.849-.977C6.845 4.16 7.369 4 8 4a2.76 2.76 0 0 1 1.637.525c.503.377.863.965.863 1.725 0 .448-.115.83-.329 1.15-.205.307-.47.513-.692.662-.109.072-.22.138-.313.195l-.006.004a6 6 0 0 0-.26.16 1 1 0 0 0-.276.245.75.75 0 0 1-1.248-.832c.184-.264.42-.489.692-.661q.154-.1.313-.195l.007-.004c.1-.061.182-.11.258-.161a1 1 0 0 0 .277-.245C8.96 6.514 9 6.427 9 6.25a.61.61 0 0 0-.262-.525A1.27 1.27 0 0 0 8 5.5c-.369 0-.595.09-.74.187a1 1 0 0 0-.34.398M9 11a1 1 0 1 1-2 0 1 1 0 0 1 2 0"/></svg>
						Help
					</a>
					
					<div class="divider"></div>
					<a class="item link-action" href data-url="/user/logout">
						<svg viewBox="0 0 16 16" class="svg octicon-sign-out" aria-hidden="true" width="16" height="16"><path d="M2 2.75C2 1.784 2.784 1 3.75 1h2.5a.75.75 0 0 1 0 1.5h-2.5a.25.25 0 0 0-.25.25v10.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 2 13.25Zm10.44 4.5-1.97-1.97a.749.749 0 0 1 .326-1.275.75.75 0 0 1 .734.215l3.25 3.25a.75.75 0 0 1 0 1.06l-3.25 3.25a.749.749 0 0 1-1.275-.326.75.75 0 0 1 .215-.734l1.97-1.97H6.75a.75.75 0 0 1 0-1.5Z"/></svg>
						Sign Out
					</a>
				</div>
			</div>
		
	</div>

	
	
</nav>

		



<div role="main" aria-label="compy-project/dev/docs/compy-lua-game-patterns.md at main" class="page-content repository file list ">
	<div class="secondary-nav">

	<div class="ui container">
		<div class="repo-header">
			<div class="flex-item tw-items-center">
				<div class="flex-item-leading">
					

	<svg viewBox="0 0 16 16" class="svg octicon-repo" aria-hidden="true" width="24" height="24"><path d="M2 2.5A2.5 2.5 0 0 1 4.5 0h8.75a.75.75 0 0 1 .75.75v12.5a.75.75 0 0 1-.75.75h-2.5a.75.75 0 0 1 0-1.5h1.75v-2h-8a1 1 0 0 0-.714 1.7.75.75 0 1 1-1.072 1.05A2.5 2.5 0 0 1 2 11.5Zm10.5-1h-8a1 1 0 0 0-1 1v6.708A2.5 2.5 0 0 1 4.5 9h8ZM5 12.25a.25.25 0 0 1 .25-.25h3.5a.25.25 0 0 1 .25.25v3.25a.25.25 0 0 1-.4.2l-1.45-1.087a.25.25 0 0 0-.3 0L5.4 15.7a.25.25 0 0 1-.4-.2Z"/></svg>


				</div>
				<div class="flex-item-main">
					<div class="flex-item-title tw-text-18">
						<a class="muted tw-font-normal" href="/educationmatters">educationmatters</a>/<a class="muted" href="/educationmatters/compy-project">compy-project</a>
					</div>
				</div>
				<div class="flex-item-trailing">
					
					
						<span class="ui basic label not-mobile">Private</span>
						<div class="repo-icon only-mobile" data-tooltip-content="Private"><svg viewBox="0 0 16 16" class="svg octicon-lock" aria-hidden="true" width="18" height="18"><path d="M4 4a4 4 0 0 1 8 0v2h.25c.966 0 1.75.784 1.75 1.75v5.5A1.75 1.75 0 0 1 12.25 15h-8.5A1.75 1.75 0 0 1 2 13.25v-5.5C2 6.784 2.784 6 3.75 6H4Zm8.25 3.5h-8.5a.25.25 0 0 0-.25.25v5.5c0 .138.112.25.25.25h8.5a.25.25 0 0 0 .25-.25v-5.5a.25.25 0 0 0-.25-.25M10.5 6V4a2.5 2.5 0 1 0-5 0v2Z"/></svg></div>
					
					
					
					
				</div>
			</div>
			
				<div class="flex-text-block tw-flex-wrap">
					
					
					
					<a class="ui compact small basic button" href="/educationmatters/compy-project.rss" data-tooltip-content="RSS Feed">
						<svg viewBox="0 0 16 16" class="svg octicon-rss" aria-hidden="true" width="16" height="16"><path d="M2.002 2.725a.75.75 0 0 1 .797-.699C8.79 2.42 13.58 7.21 13.974 13.201a.75.75 0 0 1-1.497.098 10.5 10.5 0 0 0-9.776-9.776.747.747 0 0 1-.7-.798ZM2.84 7.05h-.002a7 7 0 0 1 6.113 6.111.75.75 0 0 1-1.49.178 5.5 5.5 0 0 0-4.8-4.8.75.75 0 0 1 .179-1.489M2 13a1 1 0 1 1 2 0 1 1 0 0 1-2 0"/></svg>
					</a>
					
					<form class="flex-text-inline" hx-boost="true" hx-target="this" method="post" action="/educationmatters/compy-project/action/unwatch">
	<div class="ui labeled button" >
		
		
		<button type="submit" class="ui compact small basic button" aria-label="Unwatch">
			<svg viewBox="0 0 16 16" class="svg octicon-eye" aria-hidden="true" width="16" height="16"><path d="M8 2c1.981 0 3.671.992 4.933 2.078 1.27 1.091 2.187 2.345 2.637 3.023a1.62 1.62 0 0 1 0 1.798c-.45.678-1.367 1.932-2.637 3.023C11.67 13.008 9.981 14 8 14s-3.671-.992-4.933-2.078C1.797 10.83.88 9.576.43 8.898a1.62 1.62 0 0 1 0-1.798c.45-.677 1.367-1.931 2.637-3.022C4.33 2.992 6.019 2 8 2M1.679 7.932a.12.12 0 0 0 0 .136c.411.622 1.241 1.75 2.366 2.717C5.176 11.758 6.527 12.5 8 12.5s2.825-.742 3.955-1.715c1.124-.967 1.954-2.096 2.366-2.717a.12.12 0 0 0 0-.136c-.412-.621-1.242-1.75-2.366-2.717C10.824 4.242 9.473 3.5 8 3.5s-2.825.742-3.955 1.715c-1.124.967-1.954 2.096-2.366 2.717M8 10a2 2 0 1 1-.001-3.999A2 2 0 0 1 8 10"/></svg>
			<span class="not-mobile" aria-hidden="true">Unwatch</span>
		</button>
		<a hx-boost="false" class="ui basic label" href="/educationmatters/compy-project/watchers">
			14
		</a>
	</div>
</form>

					
					<form class="flex-text-inline" hx-boost="true" hx-target="this" method="post" action="/educationmatters/compy-project/action/star">
	<div class="ui labeled button" >
		
		
		<button type="submit" class="ui compact small basic button" aria-label="Star">
			<svg viewBox="0 0 16 16" class="svg octicon-star" aria-hidden="true" width="16" height="16"><path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.751.751 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25m0 2.445L6.615 5.5a.75.75 0 0 1-.564.41l-3.097.45 2.24 2.184a.75.75 0 0 1 .216.664l-.528 3.084 2.769-1.456a.75.75 0 0 1 .698 0l2.77 1.456-.53-3.084a.75.75 0 0 1 .216-.664l2.24-2.183-3.096-.45a.75.75 0 0 1-.564-.41z"/></svg>
			<span class="not-mobile" aria-hidden="true">Star</span>
		</button>
		<a hx-boost="false" class="ui basic label" href="/educationmatters/compy-project/stars">
			0
		</a>
	</div>
</form>

					
					
						<div class="ui labeled button
							"
							
						>
							<a class="ui compact small basic button"
								
									href="/educationmatters/compy-project/fork"
								
							>
								<svg viewBox="0 0 16 16" class="svg octicon-repo-forked" aria-hidden="true" width="16" height="16"><path d="M5 5.372v.878c0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75v-.878a2.25 2.25 0 1 1 1.5 0v.878a2.25 2.25 0 0 1-2.25 2.25h-1.5v2.128a2.251 2.251 0 1 1-1.5 0V8.5h-1.5A2.25 2.25 0 0 1 3.5 6.25v-.878a2.25 2.25 0 1 1 1.5 0M5 3.25a.75.75 0 1 0-1.5 0 .75.75 0 0 0 1.5 0m6.75.75a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5m-3 8.75a.75.75 0 1 0-1.5 0 .75.75 0 0 0 1.5 0"/></svg><span class="text not-mobile">Fork</span>
							</a>
							<a class="ui basic label" href="/educationmatters/compy-project/forks">
								0
							</a>
						</div>
						<div class="ui small modal" id="fork-repo-modal">
							<div class="header">
								You've already forked compy-project
							</div>
							<div class="content tw-text-left">
								<div class="ui list">
									
								</div>
								
								<div class="divider"></div>
								<a href="/educationmatters/compy-project/fork">Fork to a different account</a>
								
							</div>
						</div>
					
				</div>
			
		</div>
		
		
		
	</div>

	<div class="ui container">
		<overflow-menu class="ui secondary pointing menu">
			
				<div class="overflow-menu-items">
					
					<a class="active item" href="/educationmatters/compy-project">
						<svg viewBox="0 0 16 16" class="svg octicon-code" aria-hidden="true" width="16" height="16"><path d="m11.28 3.22 4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.749.749 0 0 1-1.275-.326.75.75 0 0 1 .215-.734L13.94 8l-3.72-3.72a.749.749 0 0 1 .326-1.275.75.75 0 0 1 .734.215m-6.56 0a.75.75 0 0 1 1.042.018.75.75 0 0 1 .018 1.042L2.06 8l3.72 3.72a.749.749 0 0 1-.326 1.275.75.75 0 0 1-.734-.215L.47 8.53a.75.75 0 0 1 0-1.06Z"/></svg> Code
					</a>
					

					
						<a class="item" href="/educationmatters/compy-project/issues">
							<svg viewBox="0 0 16 16" class="svg octicon-issue-opened" aria-hidden="true" width="16" height="16"><path d="M8 9.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3"/><path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0M1.5 8a6.5 6.5 0 1 0 13 0 6.5 6.5 0 0 0-13 0"/></svg> Issues
							
						</a>
					

					

					
						<a class="item" href="/educationmatters/compy-project/pulls">
							<svg viewBox="0 0 16 16" class="svg octicon-git-pull-request" aria-hidden="true" width="16" height="16"><path d="M1.5 3.25a2.25 2.25 0 1 1 3 2.122v5.256a2.251 2.251 0 1 1-1.5 0V5.372A2.25 2.25 0 0 1 1.5 3.25m5.677-.177L9.573.677A.25.25 0 0 1 10 .854V2.5h1A2.5 2.5 0 0 1 13.5 5v5.628a2.251 2.251 0 1 1-1.5 0V5a1 1 0 0 0-1-1h-1v1.646a.25.25 0 0 1-.427.177L7.177 3.427a.25.25 0 0 1 0-.354M3.75 2.5a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5m0 9.5a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5m8.25.75a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0"/></svg> Pull Requests
							
						</a>
					

					
						<a class="item" href="/educationmatters/compy-project/actions">
							<svg viewBox="0 0 16 16" class="svg octicon-play" aria-hidden="true" width="16" height="16"><path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0M1.5 8a6.5 6.5 0 1 0 13 0 6.5 6.5 0 0 0-13 0m4.879-2.773 4.264 2.559a.25.25 0 0 1 0 .428l-4.264 2.559A.25.25 0 0 1 6 10.559V5.442a.25.25 0 0 1 .379-.215"/></svg> Actions
							
						</a>
					

					
						<a href="/educationmatters/compy-project/packages" class="item">
							<svg viewBox="0 0 16 16" class="svg octicon-package" aria-hidden="true" width="16" height="16"><path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0M7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.25.25 0 0 0-.25 0M2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"/></svg> Packages
						</a>
					

					
					
						<a href="/educationmatters/compy-project/projects" class="item">
							<svg viewBox="0 0 16 16" class="svg octicon-project" aria-hidden="true" width="16" height="16"><path d="M1.75 0h12.5C15.216 0 16 .784 16 1.75v12.5A1.75 1.75 0 0 1 14.25 16H1.75A1.75 1.75 0 0 1 0 14.25V1.75C0 .784.784 0 1.75 0M1.5 1.75v12.5c0 .138.112.25.25.25h12.5a.25.25 0 0 0 .25-.25V1.75a.25.25 0 0 0-.25-.25H1.75a.25.25 0 0 0-.25.25M11.75 3a.75.75 0 0 1 .75.75v7.5a.75.75 0 0 1-1.5 0v-7.5a.75.75 0 0 1 .75-.75m-8.25.75a.75.75 0 0 1 1.5 0v5.5a.75.75 0 0 1-1.5 0ZM8 3a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 8 3"/></svg> Projects
							
						</a>
					

					
					<a class="item" href="/educationmatters/compy-project/releases">
						<svg viewBox="0 0 16 16" class="svg octicon-tag" aria-hidden="true" width="16" height="16"><path d="M1 7.775V2.75C1 1.784 1.784 1 2.75 1h5.025c.464 0 .91.184 1.238.513l6.25 6.25a1.75 1.75 0 0 1 0 2.474l-5.026 5.026a1.75 1.75 0 0 1-2.474 0l-6.25-6.25A1.75 1.75 0 0 1 1 7.775m1.5 0c0 .066.026.13.073.177l6.25 6.25a.25.25 0 0 0 .354 0l5.025-5.025a.25.25 0 0 0 0-.354l-6.25-6.25a.25.25 0 0 0-.177-.073H2.75a.25.25 0 0 0-.25.25ZM6 5a1 1 0 1 1 0 2 1 1 0 0 1 0-2"/></svg> Releases
						
					</a>
					

					
						<a class="item" href="/educationmatters/compy-project/wiki">
							<svg viewBox="0 0 16 16" class="svg octicon-book" aria-hidden="true" width="16" height="16"><path d="M0 1.75A.75.75 0 0 1 .75 1h4.253c1.227 0 2.317.59 3 1.501A3.74 3.74 0 0 1 11.006 1h4.245a.75.75 0 0 1 .75.75v10.5a.75.75 0 0 1-.75.75h-4.507a2.25 2.25 0 0 0-1.591.659l-.622.621a.75.75 0 0 1-1.06 0l-.622-.621A2.25 2.25 0 0 0 5.258 13H.75a.75.75 0 0 1-.75-.75Zm7.251 10.324.004-5.073-.002-2.253A2.25 2.25 0 0 0 5.003 2.5H1.5v9h3.757a3.75 3.75 0 0 1 1.994.574M8.755 4.75l-.004 7.322a3.75 3.75 0 0 1 1.992-.572H14.5v-9h-3.495a2.25 2.25 0 0 0-2.25 2.25"/></svg> Wiki
						</a>
					

					

					
						<a class="item" href="/educationmatters/compy-project/activity">
							<svg viewBox="0 0 16 16" class="svg octicon-pulse" aria-hidden="true" width="16" height="16"><path d="M6 2c.306 0 .582.187.696.471L10 10.731l1.304-3.26A.75.75 0 0 1 12 7h3.25a.75.75 0 0 1 0 1.5h-2.742l-1.812 4.528a.751.751 0 0 1-1.392 0L6 4.77 4.696 8.03A.75.75 0 0 1 4 8.5H.75a.75.75 0 0 1 0-1.5h2.742l1.812-4.529A.75.75 0 0 1 6 2"/></svg> Activity
						</a>
					

					

					
						<span class="item-flex-space"></span>
						<a class=" item" href="/educationmatters/compy-project/settings">
							<svg viewBox="0 0 16 16" class="svg octicon-tools" aria-hidden="true" width="16" height="16"><path d="M5.433 2.304A4.49 4.49 0 0 0 3.5 6c0 1.598.832 3.002 2.09 3.802.518.328.929.923.902 1.64v.008l-.164 3.337a.75.75 0 1 1-1.498-.073l.163-3.33c.002-.085-.05-.216-.207-.316A6 6 0 0 1 2 6a6 6 0 0 1 2.567-4.92 1.48 1.48 0 0 1 1.673-.04c.462.296.76.827.76 1.423v2.82c0 .082.041.16.11.206l.75.51a.25.25 0 0 0 .28 0l.75-.51A.25.25 0 0 0 9 5.282V2.463c0-.596.298-1.127.76-1.423a1.48 1.48 0 0 1 1.673.04A6 6 0 0 1 14 6a6 6 0 0 1-2.786 5.068c-.157.1-.209.23-.207.315l.163 3.33a.752.752 0 0 1-1.094.714.75.75 0 0 1-.404-.64l-.164-3.345c-.027-.717.384-1.312.902-1.64A4.5 4.5 0 0 0 12.5 6a4.49 4.49 0 0 0-1.933-3.696c-.024.017-.067.067-.067.16v2.818a1.75 1.75 0 0 1-.767 1.448l-.75.51a1.75 1.75 0 0 1-1.966 0l-.75-.51A1.75 1.75 0 0 1 5.5 5.282V2.463c0-.092-.043-.142-.067-.159"/></svg> Settings
						</a>
					
				</div>
			
		</overflow-menu>
	</div>
	<div class="ui tabs divider"></div>
</div>

	<div class="ui container fluid padded">
		

		

		




		<div class="repo-view-container">
			<div class="tw-flex tw-flex-col repo-view-file-tree-container not-mobile " data-user-is-signed-in>
				<div class="flex-text-block repo-button-row">
	<button class="ui compact basic icon button"
		data-global-click="onRepoViewFileTreeToggle" data-toggle-action="hide"
		data-tooltip-content="Hide file tree">
		<svg viewBox="0 0 16 16" class="svg octicon-sidebar-expand" aria-hidden="true" width="16" height="16"><path d="m4.177 7.823 2.396-2.396A.25.25 0 0 1 7 5.604v4.792a.25.25 0 0 1-.427.177L4.177 8.177a.25.25 0 0 1 0-.354"/><path d="M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784 16 1.75v12.5A1.75 1.75 0 0 1 14.25 16H1.75A1.75 1.75 0 0 1 0 14.25Zm1.75-.25a.25.25 0 0 0-.25.25v12.5c0 .138.112.25.25.25H9.5v-13Zm12.5 13a.25.25 0 0 0 .25-.25V1.75a.25.25 0 0 0-.25-.25H11v13Z"/></svg>
	</button>
	<b>Files</b>
</div>


<div id="view-file-tree" class="tw-overflow-auto tw-h-full is-loading"
	data-repo-link="/educationmatters/compy-project"
	data-tree-path="dev/docs/compy-lua-game-patterns.md"
	data-current-ref-name-sub-url="branch/main"
></div>

			</div>
			<div class="repo-view-content">
				

<div class="repo-view-content-data tw-hidden" data-document-title="compy-project/dev/docs/compy-lua-game-patterns.md at main" data-document-title-common="compy-project - git for baldvin.net"></div>


<div class="repo-button-row">
	<div class="repo-button-row-left">
	
		<button class="repo-view-file-tree-toggle-show ui compact basic button icon not-mobile tw-hidden"
			data-global-click="onRepoViewFileTreeToggle" data-toggle-action="show"
			data-tooltip-content="Show file tree">
			<svg viewBox="0 0 16 16" class="svg octicon-sidebar-collapse" aria-hidden="true" width="16" height="16"><path d="M6.823 7.823a.25.25 0 0 1 0 .354l-2.396 2.396A.25.25 0 0 1 4 10.396V5.604a.25.25 0 0 1 .427-.177Z"/><path d="M1.75 0h12.5C15.216 0 16 .784 16 1.75v12.5A1.75 1.75 0 0 1 14.25 16H1.75A1.75 1.75 0 0 1 0 14.25V1.75C0 .784.784 0 1.75 0M1.5 1.75v12.5c0 .138.112.25.25.25H9.5v-13H1.75a.25.25 0 0 0-.25.25M11 14.5h3.25a.25.25 0 0 0 .25-.25V1.75a.25.25 0 0 0-.25-.25H11Z"/></svg>
		</button>
	

	
<div class=""
	data-global-init="initRepoBranchTagSelector"
	data-text-release-compare="Compare"
	data-text-branches="Branches"
	data-text-tags="Tags"
	data-text-filter-branch="Filter branch"
	data-text-filter-tag="Find tag"
	data-text-default-branch-label="default"
	data-text-create-tag="Create tag %s"
	data-text-create-branch="Create branch %s"
	data-text-create-ref-from="from &#34;%s&#34;"
	data-text-no-results="No results found."
	data-text-view-all-branches="View all branches"
	data-text-view-all-tags="View all tags"

	data-current-repo-default-branch="main"
	data-current-repo-link="/educationmatters/compy-project"
	data-current-tree-path="dev/docs/compy-lua-game-patterns.md"
	data-current-ref-type="branch"
	data-current-ref-short-name="main"

	data-ref-link-template="{RepoLink}/src/{RefType}/{RefShortName}/{TreePath}"
	data-ref-form-action-template=""
	data-dropdown-fixed-text=""
	data-show-tab-branches="true"
	data-show-tab-tags="true"
	data-allow-create-new-ref="true"
	data-show-view-all-refs-entry="true"

	data-enable-feed="true"
>
	
	<div class="ui dropdown custom branch-selector-dropdown ellipsis-text-items">
		<div class="ui compact button branch-dropdown-button">
			<span class="flex-text-block gt-ellipsis">
				
					
						<svg viewBox="0 0 16 16" class="svg octicon-git-branch" aria-hidden="true" width="16" height="16"><path d="M9.5 3.25a2.25 2.25 0 1 1 3 2.122V6A2.5 2.5 0 0 1 10 8.5H6a1 1 0 0 0-1 1v1.128a2.251 2.251 0 1 1-1.5 0V5.372a2.25 2.25 0 1 1 1.5 0v1.836A2.5 2.5 0 0 1 6 7h4a1 1 0 0 0 1-1v-.628A2.25 2.25 0 0 1 9.5 3.25m-6 0a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0m8.25-.75a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5M4.25 12a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5"/></svg>
					
					<strong class="tw-inline-block gt-ellipsis">main</strong>
				
			</span>
			<svg viewBox="0 0 16 16" class="dropdown icon svg octicon-triangle-down" aria-hidden="true" width="14" height="14"><path d="m4.427 7.427 3.396 3.396a.25.25 0 0 0 .354 0l3.396-3.396A.25.25 0 0 0 11.396 7H4.604a.25.25 0 0 0-.177.427"/></svg>
		</div>
	</div>
</div>


	
		
		
		
		
		<a id="new-pull-request" role="button" class="ui compact basic button" href="/educationmatters/compy-project/compare/main...main?expand=1"
			data-tooltip-content="New Pull Request">
			<svg viewBox="0 0 16 16" class="svg octicon-git-pull-request" aria-hidden="true" width="16" height="16"><path d="M1.5 3.25a2.25 2.25 0 1 1 3 2.122v5.256a2.251 2.251 0 1 1-1.5 0V5.372A2.25 2.25 0 0 1 1.5 3.25m5.677-.177L9.573.677A.25.25 0 0 1 10 .854V2.5h1A2.5 2.5 0 0 1 13.5 5v5.628a2.251 2.251 0 1 1-1.5 0V5a1 1 0 0 0-1-1h-1v1.646a.25.25 0 0 1-.427.177L7.177 3.427a.25.25 0 0 1 0-.354M3.75 2.5a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5m0 9.5a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5m8.25.75a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0"/></svg>
		</a>
	

	
	

	

	

	
		
		<span class="breadcrumb">
			<a class="section" href="/educationmatters/compy-project/src/branch/main" title="compy-project">compy-project</a><span class="breadcrumb-divider">/</span><span class="section"><a href="/educationmatters/compy-project/src/branch/main/dev" title="dev">dev</a></span><span class="breadcrumb-divider">/</span><span class="section"><a href="/educationmatters/compy-project/src/branch/main/dev/docs" title="docs">docs</a></span><span class="breadcrumb-divider">/</span><span class="active section" title="compy-lua-game-patterns.md">compy-lua-game-patterns.md</span>
					<button class="btn interact-fg tw-mx-1" data-clipboard-text="dev/docs/compy-lua-game-patterns.md" data-tooltip-content="Copy path"><svg viewBox="0 0 16 16" class="svg octicon-copy" aria-hidden="true" width="14" height="14"><path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"/><path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/></svg></button></span>
	
	</div>

	<div class="repo-button-row-right">
		
		
		
	</div>
</div>

	<div  class="tab-size-4 non-diff-file-content"
	data-global-init="initRepoFileView" data-raw-file-link="/educationmatters/compy-project/raw/branch/main/dev/docs/compy-lua-game-patterns.md">

	
		<div id="repo-file-commit-box" class="ui segment list-header tw-mb-4 tw-flex tw-justify-between">
			<div class="latest-commit">

	
		
			<img loading="lazy" alt class="ui avatar tw-align-middle" src="/assets/img/avatar_default.png" title="dsent" width="24" height="24"/>
			<span class="author-wrapper" title="dsent"><strong>dsent</strong></span>
		
	

	<a href="/educationmatters/compy-project/commit/ac763b2ebd96e2043ab613df3ae3588c6afbcdb9" class="ui label commit-id-short " rel="nofollow">ac763b2ebd</a>

	


	
	<span class="grey commit-summary" title="agent-harness: compy-games repo guidance update"><span class="message-wrapper"><a href="/educationmatters/compy-project/commit/ac763b2ebd96e2043ab613df3ae3588c6afbcdb9" class="muted">agent-harness: compy-games repo guidance update</a></span>
		
	</span>

</div>

			
				
					<div class="text grey age flex-text-block">
						<relative-time prefix="" tense="past" datetime="2026-06-03T10:22:11+02:00" data-tooltip-content data-tooltip-interactive="true">2026-06-03 10:22:11 +02:00</relative-time>
					</div>
				
			
		</div>
	

	<h4 class="file-header ui top attached header tw-flex tw-items-center tw-justify-between tw-flex-wrap">
		<div class="file-header-left tw-flex tw-items-center tw-py-2 tw-pr-4">
			
				<div class="file-info tw-font-mono">
	
	
	
		<div class="file-info-entry">
			<span class="file-info-size">2.0 KiB</span>
		</div>
	
	
	
	
	
	
	
</div>

			
		</div>
		<div class="file-header-right file-actions flex-text-block tw-flex-wrap">
			
			<div class="ui compact icon buttons file-view-toggle-buttons ">
				
				<a href="?display=source" class="ui mini basic button file-view-toggle-source " data-tooltip-content="View Source"><svg viewBox="0 0 16 16" class="svg octicon-code" aria-hidden="true" width="15" height="15"><path d="m11.28 3.22 4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.749.749 0 0 1-1.275-.326.75.75 0 0 1 .215-.734L13.94 8l-3.72-3.72a.749.749 0 0 1 .326-1.275.75.75 0 0 1 .734.215m-6.56 0a.75.75 0 0 1 1.042.018.75.75 0 0 1 .018 1.042L2.06 8l3.72 3.72a.749.749 0 0 1-.326 1.275.75.75 0 0 1-.734-.215L.47 8.53a.75.75 0 0 1 0-1.06Z"/></svg></a>
				
				<a href="?display=rendered" class="ui mini basic button file-view-toggle-rendered active" data-tooltip-content="View Rendered"><svg viewBox="0 0 16 16" class="svg octicon-file" aria-hidden="true" width="15" height="15"><path d="M2 1.75C2 .784 2.784 0 3.75 0h6.586c.464 0 .909.184 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v9.586A1.75 1.75 0 0 1 13.25 16h-9.5A1.75 1.75 0 0 1 2 14.25Zm1.75-.25a.25.25 0 0 0-.25.25v12.5c0 .138.112.25.25.25h9.5a.25.25 0 0 0 .25-.25V6h-2.75A1.75 1.75 0 0 1 9 4.25V1.5Zm6.75.062V4.25c0 .138.112.25.25.25h2.688l-.011-.013-2.914-2.914z"/></svg></a>
			</div>
			
				<div class="ui buttons tw-mr-1">
					<a class="ui mini basic button" href="/educationmatters/compy-project/raw/branch/main/dev/docs/compy-lua-game-patterns.md">Raw</a>
					
						<a class="ui mini basic button" href="/educationmatters/compy-project/src/commit/220158f56e5e6596634db38861f71cee31ece6c1/dev/docs/compy-lua-game-patterns.md">Permalink</a>
					
					
						<a class="ui mini basic button" href="/educationmatters/compy-project/blame/branch/main/dev/docs/compy-lua-game-patterns.md">Blame</a>
					
					<a class="ui mini basic button" href="/educationmatters/compy-project/commits/branch/main/dev/docs/compy-lua-game-patterns.md">History</a>
					
				</div>
				<a download class="btn-octicon" data-tooltip-content="Download file" href="/educationmatters/compy-project/raw/branch/main/dev/docs/compy-lua-game-patterns.md"><svg viewBox="0 0 16 16" class="svg octicon-download" aria-hidden="true" width="16" height="16"><path d="M2.75 14A1.75 1.75 0 0 1 1 12.25v-2.5a.75.75 0 0 1 1.5 0v2.5c0 .138.112.25.25.25h10.5a.25.25 0 0 0 .25-.25v-2.5a.75.75 0 0 1 1.5 0v2.5A1.75 1.75 0 0 1 13.25 14Z"/><path d="M7.25 7.689V2a.75.75 0 0 1 1.5 0v5.689l1.97-1.969a.749.749 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 6.78a.749.749 0 1 1 1.06-1.06z"/></svg></a>
				<a class="btn-octicon " data-global-click="onCopyContentButtonClick"
					data-raw-file-link="/educationmatters/compy-project/raw/branch/main/dev/docs/compy-lua-game-patterns.md"
					data-tooltip-content="Copy content"
				><svg viewBox="0 0 16 16" class="svg octicon-copy" aria-hidden="true" width="16" height="16"><path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"/><path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/></svg></a>
				
				<a class="btn-octicon" href="/educationmatters/compy-project/rss/branch/main/dev/docs/compy-lua-game-patterns.md" data-tooltip-content="RSS Feed">
					<svg viewBox="0 0 16 16" class="svg octicon-rss" aria-hidden="true" width="16" height="16"><path d="M2.002 2.725a.75.75 0 0 1 .797-.699C8.79 2.42 13.58 7.21 13.974 13.201a.75.75 0 0 1-1.497.098 10.5 10.5 0 0 0-9.776-9.776.747.747 0 0 1-.7-.798ZM2.84 7.05h-.002a7 7 0 0 1 6.113 6.111.75.75 0 0 1-1.49.178 5.5 5.5 0 0 0-4.8-4.8.75.75 0 0 1 .179-1.489M2 13a1 1 0 1 1 2 0 1 1 0 0 1-2 0"/></svg>
				</a>
				
				
					
						<a class="btn-octicon" data-tooltip-content="Edit File" href="/educationmatters/compy-project/_edit/main/dev/docs/compy-lua-game-patterns.md"><svg viewBox="0 0 16 16" class="svg octicon-pencil" aria-hidden="true" width="16" height="16"><path d="M11.013 1.427a1.75 1.75 0 0 1 2.474 0l1.086 1.086a1.75 1.75 0 0 1 0 2.474l-8.61 8.61c-.21.21-.47.364-.756.445l-3.251.93a.75.75 0 0 1-.927-.928l.929-3.25c.081-.286.235-.547.445-.758l8.61-8.61Zm.176 4.823L9.75 4.81l-6.286 6.287a.25.25 0 0 0-.064.108l-.558 1.953 1.953-.558a.25.25 0 0 0 .108-.064Zm1.238-3.763a.25.25 0 0 0-.354 0L10.811 3.75l1.439 1.44 1.263-1.263a.25.25 0 0 0 0-.354Z"/></svg></a>
					
					
						<a class="btn-octicon btn-octicon-danger" data-tooltip-content="Delete File" href="/educationmatters/compy-project/_delete/main/dev/docs/compy-lua-game-patterns.md"><svg viewBox="0 0 16 16" class="svg octicon-trash" aria-hidden="true" width="16" height="16"><path d="M11 1.75V3h2.25a.75.75 0 0 1 0 1.5H2.75a.75.75 0 0 1 0-1.5H5V1.75C5 .784 5.784 0 6.75 0h2.5C10.216 0 11 .784 11 1.75M4.496 6.675l.66 6.6a.25.25 0 0 0 .249.225h5.19a.25.25 0 0 0 .249-.225l.66-6.6a.75.75 0 0 1 1.492.149l-.66 6.6A1.75 1.75 0 0 1 10.595 15h-5.19a1.75 1.75 0 0 1-1.741-1.575l-.66-6.6a.75.75 0 1 1 1.492-.15M6.5 1.75V3h3V1.75a.25.25 0 0 0-.25-.25h-2.5a.25.25 0 0 0-.25.25"/></svg></a>
					
				
			
			
		</div>
	</h4>

	<div class="ui bottom attached table unstackable segment">
		
		<div class="file-view markup markdown">
			
				<details class="frontmatter-content"><summary><svg viewbox="0 0 16 16" class="svg octicon-table" aria-hidden="true" width="12" height="12"><path d="M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784 16 1.75v12.5A1.75 1.75 0 0 1 14.25 16H1.75A1.75 1.75 0 0 1 0 14.25ZM6.5 6.5v8h7.75a.25.25 0 0 0 .25-.25V6.5Zm8-1.5V1.75a.25.25 0 0 0-.25-.25H6.5V5Zm-13 1.5v7.75c0 .138.112.25.25.25H5v-8ZM5 5V1.5H1.75a.25.25 0 0 0-.25.25V5Z"></path></svg> description, status, audience</summary><table>
<thead>
<tr>
<th>description</th>
<th>status</th>
<th>audience</th>
</tr>
</thead>
<tbody>
<tr>
<td>Lua design patterns for small Compy games and examples</td>
<td>active</td>
<td>developer</td>
</tr>
</tbody>
</table>
</details><h1 id="user-content-compy-lua-game-patterns" dir="auto">Compy Lua Game Patterns</h1>
<h2 id="user-content-scope" dir="auto">Scope</h2>
<ul dir="auto">
<li>Use these patterns for Compy games, IDE examples, and game templates.</li>
<li>For Compy IDE platform code, use <code>dev/docs/compy-ide-design-patterns.md</code>.</li>
<li>Shared Lua 5.1 runtime facts live in <code>dev/docs/compy-lua-runtime.md</code>.</li>
</ul>
<h2 id="user-content-canonical-skeleton" dir="auto">Canonical Skeleton</h2>
<div class="code-block-container code-overflow-scroll"><pre class="code-block"><code class="chroma language-lua display"><span class="n">gfx</span> <span class="o">=</span> <span class="n">love.graphics</span>

<span class="n">WIDTH</span> <span class="o">=</span> <span class="n">gfx.getWidth</span><span class="p">()</span>
<span class="n">HEIGHT</span> <span class="o">=</span> <span class="n">gfx.getHeight</span><span class="p">()</span>
<span class="n">PLAYER</span> <span class="o">=</span> <span class="p">{</span> <span class="n">x</span> <span class="o">=</span> <span class="n">WIDTH</span> <span class="o">/</span> <span class="mi">2</span><span class="p">,</span> <span class="n">y</span> <span class="o">=</span> <span class="n">HEIGHT</span> <span class="o">/</span> <span class="mi">2</span> <span class="p">}</span>

<span class="kr">function</span> <span class="nc">love</span><span class="p">.</span><span class="nf">update</span><span class="p">(</span><span class="n">dt</span><span class="p">)</span>
  <span class="n">updatePlayer</span><span class="p">(</span><span class="n">dt</span><span class="p">)</span>
<span class="kr">end</span>

<span class="kr">function</span> <span class="nc">love</span><span class="p">.</span><span class="nf">draw</span><span class="p">()</span>
  <span class="n">drawPlayer</span><span class="p">()</span>
<span class="kr">end</span>
</code></pre></div><h2 id="user-content-draw-decomposition" dir="auto">Draw Decomposition</h2>
<div class="code-block-container code-overflow-scroll"><pre class="code-block"><code class="chroma language-lua display"><span class="kr">function</span> <span class="nc">love</span><span class="p">.</span><span class="nf">draw</span><span class="p">()</span>
  <span class="n">drawBackground</span><span class="p">()</span>
  <span class="n">drawPlayer</span><span class="p">()</span>
  <span class="n">drawStatus</span><span class="p">()</span>
<span class="kr">end</span>
</code></pre></div><ul dir="auto">
<li>Keep <code>love.draw</code> as a short table of contents.</li>
<li>Put repeated shape math in named helpers.</li>
</ul>
<h2 id="user-content-helper-dispatch" dir="auto">Helper Dispatch</h2>
<div class="code-block-container code-overflow-scroll"><pre class="code-block"><code class="chroma language-lua display"><span class="n">ACTIONS</span> <span class="o">=</span> <span class="p">{</span>
  <span class="n">left</span> <span class="o">=</span> <span class="n">moveLeft</span><span class="p">,</span>
  <span class="n">right</span> <span class="o">=</span> <span class="n">moveRight</span><span class="p">,</span>
<span class="p">}</span>

<span class="kr">function</span> <span class="nc">love</span><span class="p">.</span><span class="nf">keypressed</span><span class="p">(</span><span class="n">key</span><span class="p">)</span>
  <span class="kd">local</span> <span class="n">action</span> <span class="o">=</span> <span class="n">ACTIONS</span><span class="p">[</span><span class="n">key</span><span class="p">]</span>
  <span class="kr">if</span> <span class="n">action</span> <span class="kr">then</span>
    <span class="n">action</span><span class="p">()</span>
  <span class="kr">end</span>
<span class="kr">end</span>
</code></pre></div><h2 id="user-content-state" dir="auto">State</h2>
<ul dir="auto">
<li>Use individual globals for tiny examples.</li>
<li>Use one global table for non-trivial game state.</li>
<li>Keep all file-level variables global, including aliases and constants.</li>
<li>Do not use module-scope <code>local</code> (except in performance-critical or
generated code).</li>
</ul>
<h2 id="user-content-input" dir="auto">Input</h2>
<div class="code-block-container code-overflow-scroll"><pre class="code-block"><code class="chroma language-lua display"><span class="kr">function</span> <span class="nc">love</span><span class="p">.</span><span class="nf">keypressed</span><span class="p">(</span><span class="n">key</span><span class="p">)</span>
  <span class="kr">if</span> <span class="n">key</span> <span class="o">==</span> <span class="s2">&#34;space&#34;</span> <span class="kr">then</span>
    <span class="n">RUNNING</span> <span class="o">=</span> <span class="ow">not</span> <span class="n">RUNNING</span>
  <span class="kr">end</span>
<span class="kr">end</span>
</code></pre></div><ul dir="auto">
<li>Use key callbacks for discrete actions.</li>
<li>Use <code>love.keyboard.isDown</code> for continuous movement.</li>
</ul>
<h2 id="user-content-frame-independent-motion" dir="auto">Frame-Independent Motion</h2>
<div class="code-block-container code-overflow-scroll"><pre class="code-block"><code class="chroma language-lua display"><span class="kr">function</span> <span class="nf">updateBall</span><span class="p">(</span><span class="n">dt</span><span class="p">)</span>
  <span class="n">BALL.x</span> <span class="o">=</span> <span class="n">BALL.x</span> <span class="o">+</span> <span class="n">BALL.dx</span> <span class="o">*</span> <span class="n">dt</span>
  <span class="n">BALL.y</span> <span class="o">=</span> <span class="n">BALL.y</span> <span class="o">+</span> <span class="n">BALL.dy</span> <span class="o">*</span> <span class="n">dt</span>
<span class="kr">end</span>
</code></pre></div><h2 id="user-content-color-palette" dir="auto">Color Palette</h2>
<div class="code-block-container code-overflow-scroll"><pre class="code-block"><code class="chroma language-lua display"><span class="n">gfx.setBackgroundColor</span><span class="p">(</span><span class="n">Color</span><span class="p">[</span><span class="mi">0</span><span class="p">])</span>
<span class="n">gfx.setColor</span><span class="p">(</span><span class="n">Color</span><span class="p">[</span><span class="mi">2</span> <span class="o">+</span> <span class="n">Color.bright</span><span class="p">])</span>
</code></pre></div><ul dir="auto">
<li>Prefer palette colors over raw RGB values.</li>
<li>Use brightness as state feedback.</li>
</ul>
<h2 id="user-content-anti-patterns" dir="auto">Anti-Patterns</h2>
<ul dir="auto">
<li>No metatables.</li>
<li>No coroutines.</li>
<li>No nested functions.</li>
<li>No <code>love.load</code>.</li>
<li>No raw RGB values in published examples.</li>
<li>No module-scope <code>local</code> for file-level variables.</li>
<li>No single-quoted string literals.</li>
<li>No compound conditions directly in <code>if</code> or <code>while</code>.</li>
</ul>

			
		</div>

		<div class="code-line-menu tippy-target">
			
			<a class="item ref-in-new-issue" role="menuitem" data-url-issue-new="/educationmatters/compy-project/issues/new" data-url-param-body-link="/educationmatters/compy-project/src/commit/220158f56e5e6596634db38861f71cee31ece6c1/dev/docs/compy-lua-game-patterns.md?display=source" rel="nofollow noindex">Reference in New Issue</a>
			
			<a class="item view_git_blame" role="menuitem" href="/educationmatters/compy-project/blame/commit/220158f56e5e6596634db38861f71cee31ece6c1/dev/docs/compy-lua-game-patterns.md">View Git Blame</a>
			<a class="item copy-line-permalink" role="menuitem" data-url="/educationmatters/compy-project/src/commit/220158f56e5e6596634db38861f71cee31ece6c1/dev/docs/compy-lua-game-patterns.md?display=source">Copy Permalink</a>
		</div>
	</div>
</div>



			</div>
		</div>
	</div>
</div>


		
	</div>
	
	<footer class="page-footer" role="group" aria-label="Footer">
	<div class="left-links" role="contentinfo" aria-label="About Software">
		
			<a target="_blank" rel="noopener noreferrer" href="https://about.gitea.com">Powered by Gitea</a>
		
		
			Version:
			
				1.25.4
			
		
		
			Page: <strong>27ms</strong>
			Template: <strong>2ms</strong>
		
	</div>
	<div class="right-links" role="group" aria-label="Links">
		<div class="ui dropdown upward">
			<span class="flex-text-inline"><svg viewBox="0 0 16 16" class="svg octicon-globe" aria-hidden="true" width="14" height="14"><path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0M5.78 8.75a9.64 9.64 0 0 0 1.363 4.177q.383.64.857 1.215c.245-.296.551-.705.857-1.215A9.64 9.64 0 0 0 10.22 8.75Zm4.44-1.5a9.64 9.64 0 0 0-1.363-4.177c-.307-.51-.612-.919-.857-1.215a10 10 0 0 0-.857 1.215A9.64 9.64 0 0 0 5.78 7.25Zm-5.944 1.5H1.543a6.51 6.51 0 0 0 4.666 5.5q-.184-.271-.352-.552c-.715-1.192-1.437-2.874-1.581-4.948m-2.733-1.5h2.733c.144-2.074.866-3.756 1.58-4.948q.18-.295.353-.552a6.51 6.51 0 0 0-4.666 5.5m10.181 1.5c-.144 2.074-.866 3.756-1.58 4.948q-.18.296-.353.552a6.51 6.51 0 0 0 4.666-5.5Zm2.733-1.5a6.51 6.51 0 0 0-4.666-5.5q.184.272.353.552c.714 1.192 1.436 2.874 1.58 4.948Z"/></svg> English</span>
			<div class="menu language-menu">
				<a lang="id-ID" data-url="/?lang=id-ID" class="item ">Bahasa Indonesia</a>
				<a lang="de-DE" data-url="/?lang=de-DE" class="item ">Deutsch</a>
				<a lang="en-US" data-url="/?lang=en-US" class="item selected">English</a>
				<a lang="es-ES" data-url="/?lang=es-ES" class="item ">Español</a>
				<a lang="fr-FR" data-url="/?lang=fr-FR" class="item ">Français</a>
				<a lang="ga-IE" data-url="/?lang=ga-IE" class="item ">Gaeilge</a>
				<a lang="it-IT" data-url="/?lang=it-IT" class="item ">Italiano</a>
				<a lang="lv-LV" data-url="/?lang=lv-LV" class="item ">Latviešu</a>
				<a lang="hu-HU" data-url="/?lang=hu-HU" class="item ">Magyar nyelv</a>
				<a lang="nl-NL" data-url="/?lang=nl-NL" class="item ">Nederlands</a>
				<a lang="pl-PL" data-url="/?lang=pl-PL" class="item ">Polski</a>
				<a lang="pt-PT" data-url="/?lang=pt-PT" class="item ">Português de Portugal</a>
				<a lang="pt-BR" data-url="/?lang=pt-BR" class="item ">Português do Brasil</a>
				<a lang="fi-FI" data-url="/?lang=fi-FI" class="item ">Suomi</a>
				<a lang="sv-SE" data-url="/?lang=sv-SE" class="item ">Svenska</a>
				<a lang="tr-TR" data-url="/?lang=tr-TR" class="item ">Türkçe</a>
				<a lang="cs-CZ" data-url="/?lang=cs-CZ" class="item ">Čeština</a>
				<a lang="el-GR" data-url="/?lang=el-GR" class="item ">Ελληνικά</a>
				<a lang="bg-BG" data-url="/?lang=bg-BG" class="item ">Български</a>
				<a lang="ru-RU" data-url="/?lang=ru-RU" class="item ">Русский</a>
				<a lang="uk-UA" data-url="/?lang=uk-UA" class="item ">Українська</a>
				<a lang="fa-IR" data-url="/?lang=fa-IR" class="item ">فارسی</a>
				<a lang="ml-IN" data-url="/?lang=ml-IN" class="item ">മലയാളം</a>
				<a lang="ja-JP" data-url="/?lang=ja-JP" class="item ">日本語</a>
				<a lang="zh-CN" data-url="/?lang=zh-CN" class="item ">简体中文</a>
				<a lang="zh-TW" data-url="/?lang=zh-TW" class="item ">繁體中文（台灣）</a>
				<a lang="zh-HK" data-url="/?lang=zh-HK" class="item ">繁體中文（香港）</a>
				<a lang="ko-KR" data-url="/?lang=ko-KR" class="item ">한국어</a>
				</div>
		</div>
		<a href="/assets/licenses.txt">Licenses</a>
		<a href="/api/swagger">API</a>
		
	</div>
</footer>

	
</body>
</html>


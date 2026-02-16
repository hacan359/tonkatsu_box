# Getting Started

## Requirements

- Windows 10 or 11
- Internet connection (for initial setup and search)
- IGDB API credentials (for game search)
- TMDB API key (optional, for movie/TV show search)

## Getting IGDB API Keys

Tonkatsu Box uses IGDB to fetch game metadata. You need free API credentials:

1. Go to [dev.twitch.tv](https://dev.twitch.tv)
2. Log in with Twitch account (create one if needed)
3. Go to **Applications** → **Register Your Application**
4. Fill in:
   - Name: `Tonkatsu Box` (or anything)
   - OAuth Redirect URLs: `http://localhost`
   - Category: `Application Integration`
5. Click **Create**
6. Copy your **Client ID** and generate a **Client Secret**

## Getting TMDB API Key (Optional)

For searching movies and TV shows:

1. Go to [themoviedb.org](https://www.themoviedb.org)
2. Create an account or log in
3. Go to **Settings** → **API**
4. Request an API key (choose "Developer" type)
5. Copy your **API Key (v3 auth)**

## Getting SteamGridDB API Key (Optional)

For high-quality game artwork (grids, heroes, logos, icons):

1. Go to [steamgriddb.com](https://www.steamgriddb.com)
2. Create an account or log in
3. Go to **Preferences** → **API**
4. Copy your **API Key**

## First Launch

1. Start Tonkatsu Box
2. Enter your IGDB Client ID and Client Secret
3. Click **Verify Connection**
4. Platforms will sync automatically
5. (Optional) Enter your TMDB API Key in the **TMDB API** section for movie/TV show search
6. (Optional) Enter your SteamGridDB API Key in the **SteamGridDB API** section
7. You're ready to create collections!

## Quick Start

### Create a Collection

1. Click **+ New Collection**
2. Enter a name
3. Click **Add Items**
4. Search for a game, movie or TV show
5. Select platform (for games) or tap to add (for movies/TV shows)
6. Done!

### Import a Collection

1. Get a `.rcoll` file from someone
2. Click **Import**
3. Select the file
4. Collection appears with all game data

### Share a Collection

1. Open your collection
2. Click **Export**
3. Save the `.rcoll` file
4. Share it anywhere!

## Tips

- Use the status tracker to manage your backlog
- Add comments to remember why you added a game
- Fork interesting collections and customize them

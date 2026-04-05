# SpaceView                                                                     


![](Pulsar.png)

  A native iOS app for exploring NASA's universe of content. Browse the
  Astronomy Picture of the Day, read the latest space news, search the NASA     
  Image Library, and view live Earth imagery from the DSCOVR satellite — all
  wrapped in a deep-space visual theme.                                         
                  
 ## Features

 ### Today (APOD)

  NASA's Astronomy Picture of the Day, fetched fresh each launch. Browse        
  backwards through the full archive using the date navigation bar or jump to
  any date with the calendar picker. Images open in a fullscreen pinch-to-zoom  
  viewer with double-tap to zoom and a save-to-photos button. When the day's
  entry is a video, a YouTube thumbnail with a play button opens it in the
  browser. Every entry can be favorited with a heart button and shared via the
  system share sheet.

 ### News

  A scrollable feed of space news articles sourced from the Spaceflight News    
  API. Each card shows the source outlet, publication date, headline, summary,
  and thumbnail. Tapping an article opens it in the browser. The feed supports  
  pull-to-refresh and infinite scroll pagination.

  ### Explore

  Search the NASA Image Library by keyword or use the built-in presets — Mars,  
  Moon, and Hubble. Results load in a two-column lazy grid with infinite
  pagination. Tapping any image opens a full detail view. The search bar clears 
  with a single tap.

 ### Planets

  Browse NASA imagery organized by planet using an emoji-based planet picker.   
  Each planet loads curated results from the NASA Image Library with infinite
  scroll. The Earth tab is special — it shows the most recent natural-color     
  images from the DSCOVR/EPIC camera, including a scrollable thumbnail strip to
  browse between captures of the day, with a caption and timestamp for each
  frame.

 ### Saved

  A persistent favorites list that collects any APOD entry you've hearted.      
  Backed by FavoritesStore, which is injected as an environment object so the
  heart state stays in sync across every tab without any extra wiring.          
                  
 ## Architecture

  SpaceView follows MVVM with SwiftUI's @Observable macro (iOS 17+). Each tab   
  owns a ViewModel that drives its view, and networking is isolated to two
  service actors.                                                               
                  
 ### Services
  - NASAService — a Swift actor that calls the NASA APOD API, the NASA Image
  Library search API, and the DSCOVR/EPIC API. Errors are typed via             
  NASAServiceError with localized descriptions.                    
  - NewsService — fetches paginated articles from the Spaceflight News API.     
                  
 ### ViewModels                                                                    
  - APODViewModel — manages the selected date, previous/next navigation bounds,
  and loading state for the APOD entry.                                         
  - MarsViewModel — handles preset selection, keyword search, and paginated
  image loading for the Explore tab.                                            
  - SolarSystemViewModel — manages planet selection, EPIC image browsing index, 
  and paginated planet image loading.                                          
  - NewsViewModel — handles paginated news article fetching.                    
                  
 ## Persistence                                                                   
  - FavoritesStore — @Observable class stored in the SwiftUI environment, shared
   app-wide.                                                                    
                  
 ## Theme                                                                         
  - SpaceTheme — centralized enum holding all colors (deep-space background,
  nebula blue, star gold), gradients, and reusable typography view builders.    
  - GlassCard — a ViewModifier applying .ultraThinMaterial with a subtle white
  stroke border, used throughout the app for cards and the floating tab bar.    
  - ShimmerBox — animated shimmer placeholder shown while images load.          
                                                                      
 ## APIs                                                          
                                                            
  - api.nasa.gov/planetary/apod — Astronomy Picture of the Day
  - images-api.nasa.gov/search — NASA Image Library (search and planet browsing)
  - epic.gsfc.nasa.gov/api/natural — DSCOVR/EPIC Earth imagery (no API key
  required)                                                                     
  - Spaceflight News API — space news articles
                                                                                
  ## Setup           

  1. Clone the repo and open SpaceView.xcodeproj in Xcode.                      
  2. The project uses a NASA API key stored in NASAService.swift as apiKey.
  Replace it with your own key from https://api.nasa.gov if needed. The demo key
   works but is rate-limited.
  3. Build and run on a simulator or device running iOS 17 or later.            
                                                                                
  No Swift Package Manager dependencies — the entire app is built on Apple      
  frameworks only.                                                              
                                                                                
  ## Requirements    

  - iOS 17+                                                                     
  - Xcode 15+
                                                                                
                       

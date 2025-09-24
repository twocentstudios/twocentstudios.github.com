---
layout: post
title: "Let's Write a Train Tracking Algorithm"
date: 2025-09-22 20:00:00
image: /images/eki-live-presentation-01.jpeg
tags: ekilive apple ios presentation
---

I did a 20-minute presentation on September 20th at [iOSDC Japan 2025](https://iosdc.jp/2025/).

If you prefer video:

- Japanese (conference): (available 2025/10/22)
- English (home): [YouTube](https://youtu.be/xBQlipN0pMg)

This post is a deconstructed version of the talk with the slide images above and my speaker notes in English below.

---

![](/images/eki-live-presentation-01.jpeg)

- Lately I've been working on an app called [Eki Live](https://twocentstudios.com/2025/06/03/eki-live-announcement/).
- Today I'm going to talk about a part of that app.
- So what do I mean by train tracking algorithm?
- Well, when riding a train, it's useful to know the upcoming station.

---

![](/images/eki-live-presentation-02.jpeg)

- On the train, we can see the train information display or listen for announcements.

---

<video src="/images/eki-live-presentation-03.mp4" autoplay controls preload="true" width="100%"></video>

- But would it also be useful to see this information in your Dynamic Island?

---

![](/images/eki-live-presentation-04.jpeg)

- In my talk, we'll first review the data prerequisites we'll need for the algorithm.
- Then, we'll write each part of the algorithm, improving it step-by-step.

---

![](/images/eki-live-presentation-05.jpeg)

- We need two types of data for the train tracking algorithm:
- Static data that describes the railway system of greater Tokyo. 
- And Live GPS data from the iPhone user.

---

![](/images/eki-live-presentation-06.jpeg)

- Railways are ordered groups of Stations.
- In this example, we can see that the Minatomirai Line is made up of 6 stations.

---

![](/images/eki-live-presentation-07.jpeg)

- Trains travel in both Directions on a Railway.
- Coordinates make up the path of a Railway's physical tracks.

---

![](/images/eki-live-presentation-08.jpeg)

- This map shows the Railway data we'll be using.

---

![](/images/eki-live-presentation-09.jpeg)

- We collect live GPS data from an iPhone using the Core Location framework.
- We store the data in a local SQLite database.

---

![](/images/eki-live-presentation-10.jpeg)

- A `Location` has all data from `CLLocation`.
- Latitude, longitude, speed, course, accuracy, etc.

---

![](/images/eki-live-presentation-11.jpeg)

- A Session is an ordered list of Locations.
- A Session represents a possible journey.
- Green is for fast and red is for stopped.

---

![](/images/eki-live-presentation-12.jpeg)

- I created a macOS app to visualize the raw data.
- In the left sidebar there is a list of Sessions.
- In the bottom panel there is a list of ordered Locations for a Session.
- Clicking on a Location shows its position and course on the map.

---

![](/images/eki-live-presentation-13.jpeg)

- Our goal is to write an algorithm that determines 3 types of information:
- The Railway, the direction of the train, and the next Station.

---

![](/images/eki-live-presentation-14.jpeg)

- Here is a brief overview of the system.

---

![](/images/eki-live-presentation-15.jpeg)

- The app channels `Location` values to the algorithm.

---

![](/images/eki-live-presentation-16.jpeg)

- The algorithm reads the `Location` and gathers information from its memory.

---

![](/images/eki-live-presentation-17.jpeg)

- The algorithm updates its understanding of the device's location in the world.

---

![](/images/eki-live-presentation-18.jpeg)

- The algorithm calculates a new result set of railway, direction, and station phase.
- The result is used to update the app UI and Live Activity.

---

![](/images/eki-live-presentation-19.jpeg)

- Let's start by considering a single `Location`.
- I captured this Location while riding the Tokyu Toyoko Line close to Tsunashima Station.

---

![](/images/eki-live-presentation-20.jpeg)

- Can we determine the Railway from just this Location?

---

![](/images/eki-live-presentation-21.jpeg)

- We *do* have coordinates that outline the railway...

---

![](/images/eki-live-presentation-22.jpeg)

- First, we find the closest `RailwayCoordinate` to the `Location` for each Railway.
- Then, we order the Railways by which `RailwayCoordinate` is nearest.

---

![](/images/eki-live-presentation-23.jpeg)

- Here are our results.

---

![](/images/eki-live-presentation-24.jpeg)

- The closest `RailwayCoordinate` is from the Toyoko Line at only 12 meters away.
- The next closest `RailwayCoordinate` is from the Shin-Yokohama Line at 177 meters away.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well for *this* case.
- But...

---

![](/images/eki-live-presentation-26.jpeg)

- Let's consider another `Location`.
- This `Location` was also captured on the Toyoko Line.

---

![](/images/eki-live-presentation-27.jpeg)

- But in this section of the railway track, the Toyoko Line and Meguro Line run parallel.
- It's not possible to determine whether the correct line is Toyoko or Meguro from just this one `Location`.

---

![](/images/eki-live-presentation-28.jpeg)

- The algorithm needs to use all `Location`s from the journey.
- The example journey follows the Toyoko Line for longer than the Meguro Line.

---

![](/images/eki-live-presentation-29.jpeg)

- First, we convert the distance between the `Location` and the nearest `RailwayCoordinate` to a score.
- The score is high if close and exponentially lower when far.
- Then, we add the scores over time.

---

![](/images/eki-live-presentation-30.jpeg)

- The score from Nakameguro to Hiyoshi is now higher for the Toyoko Line than the Meguro Line.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well for this case.
- But...

---

![](/images/eki-live-presentation-32.jpeg)

- Let's consider a third `Location`.
- This `Location` was captured on the Keihin-Tohoku Line which runs the east corridor of Tokyo.

---

![](/images/eki-live-presentation-33.jpeg)

- Several lines run parallel in this corridor.
- The Tokaido Line follows the same track as the Keihin-Tohoku Line

---

![](/images/eki-live-presentation-34.jpeg)

- But the Tokaido Line skips many stations.

---

![](/images/eki-live-presentation-35.jpeg)

- If we only compare railway coordinate proximity scores, the scores will be the same.

---

![](/images/eki-live-presentation-36.jpeg)

- Let's add a small penalty to the score if a station is passed.
- If a station is passed, that indicates the iPhone may be on a parallel express railway.
- Let's also add a small penalty to the score if a train stops between stations.
- If a train stops between stations, that indicates the iPhone may be on a parallel local railway.

---

![](/images/eki-live-presentation-37.jpeg)

- Using this algorithm, the Keihin-Tohoku score is now slightly larger than the Tokaido score.

---

![](/images/eki-live-presentation-38.jpeg)

- Let's consider two example trips to better understand penalties.
- For an example trip 1 that starts at Tokyo station...

---

![](/images/eki-live-presentation-39.jpeg)

- The train stops at the second Keihin-Tohoku station.
- The Tokaido score receives a penalty since the stop occurs between stations.

---

![](/images/eki-live-presentation-40.jpeg)

- As we continue...

---

![](/images/eki-live-presentation-41.jpeg)

- The Tokaido score receives many penalties.
- Therefore, the algorithm determines the trip was on the Keihin-Tohoku Line.

---

![](/images/eki-live-presentation-42.jpeg)

- For an example trip 2 that also starts at Tokyo...

---

![](/images/eki-live-presentation-43.jpeg)

- The train passes the 2nd Keihin-Tohoku station.
- And the Keihin-Tohoku score receives a penalty.

---

![](/images/eki-live-presentation-44.jpeg)

- As we continue...

---

![](/images/eki-live-presentation-45.jpeg)

- The Keihin-Tohoku score receives many penalties.
- Therefore, the algorithm determines the trip was on the Tokaido Line.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well for this case.
- There are many more edge cases.
- However, let's continue.

---

![](/images/eki-live-presentation-48.jpeg)

- For each potential railway, we will determine which direction the train is moving.

---

![](/images/eki-live-presentation-49.jpeg)

- Every railway has 2 directions.
- We're used to seeing separate timetables on the departure board at a non-terminal station.

---

![](/images/eki-live-presentation-50.jpeg)

- For example, the Toyoko Line goes inbound towards Shibuya and outbound towards Yokohama.

---

![](/images/eki-live-presentation-51.jpeg)

- Let's consider a `Location` captured on the Toyoko Line going inbound to Shibuya.

---

![](/images/eki-live-presentation-52.jpeg)

- Once we have visited two stations, we can compare the temporal order the station visits.
- If the visit order matches the order of the stations in the database, we say that the iPhone is heading in the "ascending" direction.

---

![](/images/eki-live-presentation-53.jpeg)

- The iPhone visited Kikuna and then Okurayama.

---

![](/images/eki-live-presentation-54.jpeg)

- This ordering does not match the database, so we consider it "descending".
- In the database, "descending" maps to inbound.
- Therefore, we know the iPhone is heading inbound to Shibuya.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well for this case.
- But...
- It could take 5 minutes to determine the train direction.
- Can we do better?

---

![](/images/eki-live-presentation-56.jpeg)

- Let's use the `Location`'s course.
- Remember that course is included with some `CLLocation`s by Core Location.
- Several points moving at a decent speed are required before Core Location adds course to a `CLLocation`.
- And course itself has its own accuracy value included.

---

![](/images/eki-live-presentation-57.jpeg)

- Core Location provides an estimate of the iPhone's course in degrees.

---

![](/images/eki-live-presentation-58.jpeg)

- Note that this is *not* the iPhone's orientation using the compass.
- The course value should be the same regardless of whether the iPhone is in a pocket or held in a hand facing the rear of the train.

---

![](/images/eki-live-presentation-59.jpeg)

- The course for the example `Location` is 359.6 degrees.
- It's almost directly North.

---

![](/images/eki-live-presentation-60.jpeg)

- First, we find the 2 closest stations to the `Location`

---

![](/images/eki-live-presentation-61.jpeg)

- Next, we calculate the vector between the 2 closest stations for the "ascending" direction in our database.
- For the Toyoko line, the "ascending" direction is outbound (as mentioned earlier).
- Therefore the vector goes from Tsunashima to Okurayama.

---

![](/images/eki-live-presentation-62.jpeg)

- We need to take a quick sidebar to talk about the dot product.
- Do you remember the dot product from math class?
- We can compare the direction of unit vectors with the dot product.
- Two vectors facing the same direction have a positive dot product.
- Two vectors facing in opposite directions have a negative dot product.

---

![](/images/eki-live-presentation-63.jpeg)

- Next, we calculate the dot product between the `Location`'s course vector and the stations vector.
- If the dot product is positive, then the railway direction is "ascending".
- If the dot product is negative, then the railway direction is "descending".

---

![](/images/eki-live-presentation-65.jpeg)

- The dot product is -0.95.
- It's negative.
- Negative means "descending".
- And "descending" in our database maps to inbound for the Toyoko Line.
- Therefore, the iPhone is heading to Shibuya.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well.
- Let's move on to the last part of the algorithm.

---

![](/images/eki-live-presentation-67.jpeg)

- Finally, we can determine the next station.

---

![](/images/eki-live-presentation-68.jpeg)

- The next station is shown on the train information display.
- We'll call this the "focus station phase" going forward.
- This includes the station name (e.g. Kikuna) and its phase (e.g. Next).

---

![](/images/eki-live-presentation-69.jpeg)

- The display cycles through next, soon, and now phases for each station.

---

![](/images/eki-live-presentation-70.jpeg)

- On a map, here is where we will show each phase.

---

![](/images/eki-live-presentation-71.jpeg)

- We calculate the distance `d` and direction vector `c` from the `Location` to the closest station.
- We show the closest station `S` or the next station in the travel direction `S+1` depending on `d` and `c`. 

---

![](/images/eki-live-presentation-72.jpeg)

- When the closest station is in the travel direction, the phase will be "next".

---

![](/images/eki-live-presentation-73.jpeg)

- A `Location` less than 500m from the station will be "soon".

---

![](/images/eki-live-presentation-74.jpeg)

- A `Location` less than 200m from the station will be "now".

---

![](/images/eki-live-presentation-75.jpeg)

- Even though the `Location` is within 500m from the closest station, the station is not in the travel direction.
- Therefore, the phase will be "next" for the next station in the travel direction.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well.
- But...

---

![](/images/eki-live-presentation-77.jpeg)

- GPS data is unreliable.
- Especially within big stations.
- Especially when not moving.
- Here is an example `Location` stopped inside Kawasaki station that has an abysmal 1 km accuracy. 

---

![](/images/eki-live-presentation-78.jpeg)

- Let's create a history of `Location`s for each station.
- For each station, let's categorize each `Location` according to its distance and direction.

---

![](/images/eki-live-presentation-79.jpeg)

- In this example, "approaching" points are orange, "visiting" points are green, and the departure point is "red".

---

![](/images/eki-live-presentation-80.jpeg)

- Focus station algorithm version 2 has 3 steps.

---

![](/images/eki-live-presentation-81.jpeg)

- In step 1, we categorize a `Location` as "visiting" or "approaching" if it lies within the bounds of a Station.
- Our rule is that only 1 Station per Railway will store a unique `Location` in the `visitingLocations` or `approachingLocations` array.
- Usually, this is not an issue, but some Stations on the same Railway are within 200m of each other.
- To disambiguate, we always choose the closest Station.

---

![](/images/eki-live-presentation-82.jpeg)

- If the `Location` is outside the bounds of any Station that already has `visitingLocations` or `approachingLocations` as non-empty, we set the `firstDepartureLocation` for that Station.
- It's okay for a `Location` to be set as `firstDepartureLocation` for Station A while also being in a `visitingLocations` or `approachingLocations` array of Station B.
- Additionally, there is special handling for the startup case where a railway has no `Location`s set yet. In this case, we try to find the closest `Station` opposite the travel direction and set its `firstDepartureLocation`.
- We can then consider that `Station` the user's departure station and use it to determine the focus station.

---

![](/images/eki-live-presentation-83.jpeg)

- In step 2, we use the station history to calculate the phase for each station.

---

![](/images/eki-live-presentation-84.jpeg)

- This is a departure phase for Minami-Senju station.
- The `StationDirectionalLocationHistory` has only a `firstDepartureLocation`.

---

![](/images/eki-live-presentation-85.jpeg)

- This is an approaching phase for Kita-Senju station.
- Note: this would still count as an approaching phase even if there were only 1 `Location` in the `approachingLocations` array.

---

![](/images/eki-live-presentation-86.jpeg)

- This is a visiting phase.
- Note: this would still count as a visiting phase even if there were only 1 `Location` in the `visitingLocations` array.

---

![](/images/eki-live-presentation-87.jpeg)

- This is a visited phase.
- You can see the `firstDepartureLocation` in red.

---

![](/images/eki-live-presentation-88.jpeg)

- In step 3, we look through the station phase history for all stations to determine the focus station phase.

---

![](/images/eki-live-presentation-89a.jpeg)

- In an example, when the latest phase for Kawasaki station is visited, then the focus phase is "Next: Kamata"

---

![](/images/eki-live-presentation-89b.jpeg)

- In another example, when the latest station phase for Musashi-Kosugi station is visited and Motosumiyoshi station is approaching, then the focus phase is "Soon: Motosumiyoshi"

--- 

![](/images/eki-live-presentation-90.jpeg)

- Using a state machine gives us more stable results.

---

<video src="/images/eki-live-presentation-applause.mp4" autoplay loop preload="true" width="100%"></video>

- We did it!
- Our algorithm works well...

---

![](/images/eki-live-presentation-91.jpeg)

- But can we tell the difference between a visited station and a passed station?
- Remember, we need this information to calculate a potential penalty for the railway score.

---

![](/images/eki-live-presentation-92.jpeg)

- If the train is stopped within a station's bounds for more than 20 seconds then we consider it visited.

---

![](/images/eki-live-presentation-93.jpeg)

- If the train is moving within a station's bounds for more than 70 seconds then we also consider it visited.
- This case is for stations with bad GPS reception.

---

![](/images/eki-live-presentation-94.jpeg)

- Otherwise we consider the station as passed.

---

<video src="/images/eki-live-presentation-95a.mp4" controls preload="false" width="100%"></video>

- Now I'd like to demo the SessionViewer macOS app I created.
- I'll show a journey from Kannai station to Kawasaki station on the Keihin-Tohoku line.
- It takes some time for all `Location`s to be processed by the algorithm (top right).
- But while it's processing, I can start playback to see the journey at 10x speed (top right).
- In the inspector (right sidebar), you can see the algorithm's results updating.
- Keihin-Tohoku line has the highest score (top right).
- The direction is northbound (top right).
- The latest phase for each station is shown (middle right).

---

<video src="/images/eki-live-presentation-95b.mp4" controls preload="false" width="100%"></video>

- When we reach the last `Location` in the `Session`, we can see the full Station history (middle right).
- We can see the phase history for any station by clicking its current phase.
- When I click on a station, I can see on the map the `Location`s that were used to calculate its phase.

---

![](/images/eki-live-presentation-96.jpeg)

- The 5 iOS apps I created to collect this data are [open source on GitHub](https://github.com/twocentstudios/train-tracker-talk).
- The macOS app and algorithm are included as well.

---

![](/images/eki-live-presentation-97.jpeg)

- The algorithm is still being improved!

---

![](/images/eki-live-presentation-98.jpeg)

- But if you want to try it, Eki Live is on the [App Store](https://apps.apple.com/app/id6745218674) now.
- The app starts up automatically in the background and shows the next station in the Dynamic Island.

---

![](/images/eki-live-presentation-99.jpeg)

- Thanks for reading this presentation.
- If you have questions or comments, feel free to reach out.
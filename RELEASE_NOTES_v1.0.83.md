# v1.0.83

- Added the `2-30` Saigyouji sakura finale branch after `2-29`, with Youmu as the midboss and Yuyuko Saigyouji as the final boss.
- Added Yuyuko's intro, finale, and post-revival BGM routing, including a stronger revived phase that switches to the revival track.
- Added the `saigyouji_sakura` battlefield/selection preview, sakura arrival effects, growing graves, Yuyuko spirits, Saigyou Ayakashi tree effects, and a one-time resurrection sequence.
- Added Yuyuko and her spirit to the zombie definitions, almanac, Touhou boss frame cache, asset prewarm, and image2 exclusion/manifest checks.
- Added 24 Yuyuko boss frames with transparent cutouts and stable Godot imports; the `gpt-image-2` proxy returned 503 during the release attempt, so this release keeps the verified local expansion.
- Fixed `2-30` route events so Youmu's wraith remains a boss-summoned entity instead of appearing directly in level event tables.

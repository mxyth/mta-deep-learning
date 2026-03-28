# Deep Learning Driving

self-driving motorcycles in MTA:SA that learn to navigate through a track using neuroevolution. everything is written from scratch in pure Lua, pretty basic implementation. inspired by [Samuel Arzt's Deep Learning Cars](https://github.com/ArztSamuel/Applying_EANNs).

# Test Video

**note**: used checkpoints here to have a shorter video, current code doesn't have that. without checkpoints, bots learn how to drive kinda late 

https://github.com/user-attachments/assets/ea1412a8-fb9e-40aa-b4c7-0c3492f8256c

## what is this

bunch of NRG-500s spawn on a track. each one has a neural network brain that takes raycast data and outputs steering/throttle. a genetic algorithm breeds the best performers each generation and kills the worst.

## how to use

1. drop into `resources/`
2. `/start ml-driving-script`
3. `/mltrain` to start training
4. wait and watch

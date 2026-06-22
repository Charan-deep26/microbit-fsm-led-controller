# Finite State Machine LED Controller

An ARM Assembly project for the BBC Micro:bit V2 (nRF52833) implementing a Finite State Machine (FSM) to control the 5×5 LED matrix using direct memory-mapped I/O.

## Overview

This project demonstrates low-level embedded systems programming by implementing an 8-state LED controller entirely in ARM Assembly. Users can cycle through different LED patterns using the Micro:bit's onboard buttons.

Button A navigates to the previous pattern, while Button B navigates to the next pattern. State transitions wrap around at both ends, creating a circular finite state machine.

## Features

* 8 unique LED matrix patterns:

  * Plus
  * Cross (X)
  * Diamond
  * Checkerboard
  * Pyramid
  * Smiley Face
  * House
  * Heart
* Button-controlled state transitions
* LED matrix multiplexing
* Software debouncing
* Direct GPIO control through memory-mapped I/O
* ARM Cortex-M4 Assembly implementation

## Hardware

* BBC Micro:bit V2
* Nordic nRF52833 (ARM Cortex-M4)

## Concepts Demonstrated

* Finite State Machines (FSM)
* ARM Assembly Programming
* Memory-Mapped I/O
* GPIO Configuration and Control
* LED Matrix Multiplexing
* Bit Manipulation
* Stack Management
* Button Debouncing

## Project Structure

```text
fsm_led_controller.s   # ARM Assembly source code
project_report.pdf     # Detailed project report
demo_video.mp4         # Demonstration video
```

## How It Works

The current state is stored in a register and used to index a pattern lookup table. Each pattern is represented as a sequence of bytes encoding the LED matrix rows. The display is refreshed using row-by-row multiplexing, creating the appearance of a continuously illuminated image through persistence of vision.

Button inputs are polled continuously, and software debouncing is used to ensure reliable state transitions.

## Results

The system successfully displays all eight patterns and allows smooth navigation between states using the onboard buttons. The project provides a practical demonstration of finite state machines, embedded systems programming, and hardware-level control using ARM Assembly.

## Team Members

* Charan
* Srikar
* Sathvik
* Lokesh

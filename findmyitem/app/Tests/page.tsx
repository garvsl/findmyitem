'use client'

import React from 'react';
import speak from './utils'
import { useEffect } from 'react';


export default function Testing()
{
    const directions = [
        {
            direction: "Go forward for 50 steps", 
            time: 4000
        }, {
            direction: "Turn right in 5 steps",
            time: 2000
        }, {
            direction: "Keep going straight for 25 steps",
            time: 2000
        }
    ]

    function delay (ms: number) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async function speakDirections() {
        for (let dir of directions) {
            speak(dir.direction)
            await delay(dir.time)
        }
    }

    return(
        <>
            <div>Hello World this is the testing page</div>
            <button onClick={speakDirections}>Button</button>
        </>
    )
}
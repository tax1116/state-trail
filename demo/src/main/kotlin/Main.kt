package io.statetrail.demo

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class StateTrailDemoApplication

fun main(args: Array<String>) {
    runApplication<StateTrailDemoApplication>(*args)
}

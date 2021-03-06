module EllipticalArc2d exposing (..)

import Expect
import Fuzz exposing (Fuzzer)
import OpenSolid.Arc2d as Arc2d exposing (Arc2d)
import OpenSolid.EllipticalArc2d as EllipticalArc2d
import OpenSolid.Geometry.Expect as Expect
import OpenSolid.Geometry.Fuzz as Fuzz
import OpenSolid.Point2d as Point2d
import OpenSolid.Vector2d as Vector2d
import Test exposing (Test)


reproducibleArc : Fuzzer Arc2d
reproducibleArc =
    Fuzz.map4
        (\centerPoint startDirection radius sweptAngle ->
            let
                startPoint =
                    centerPoint
                        |> Point2d.translateBy
                            (Vector2d.with
                                { length = radius
                                , direction = startDirection
                                }
                            )
            in
            Arc2d.with
                { centerPoint = centerPoint
                , startPoint = startPoint
                , sweptAngle = sweptAngle
                }
        )
        Fuzz.point2d
        Fuzz.direction2d
        (Fuzz.floatRange 0.1 10)
        (Fuzz.floatRange -(3 * pi / 2) (3 * pi / 2))


fromEndpointsReplicatesArc : Test
fromEndpointsReplicatesArc =
    Test.fuzz2
        reproducibleArc
        Fuzz.direction2d
        "fromEndpoints accurately replicates circular arcs"
        (\arc xDirection ->
            let
                radius =
                    Arc2d.radius arc

                arcSweptAngle =
                    Arc2d.sweptAngle arc

                sweptAngle =
                    if arcSweptAngle >= pi then
                        EllipticalArc2d.largePositive
                    else if arcSweptAngle >= 0 then
                        EllipticalArc2d.smallPositive
                    else if arcSweptAngle >= -pi then
                        EllipticalArc2d.smallNegative
                    else
                        EllipticalArc2d.largeNegative

                result =
                    EllipticalArc2d.fromEndpoints
                        { startPoint = Arc2d.startPoint arc
                        , endPoint = Arc2d.endPoint arc
                        , xRadius = radius
                        , yRadius = radius
                        , xDirection = xDirection
                        , sweptAngle = sweptAngle
                        }
            in
            case result of
                Nothing ->
                    Expect.fail "fromEndpoints could not reproduce arc"

                Just ellipticalArc ->
                    EllipticalArc2d.centerPoint ellipticalArc
                        |> Expect.point2d (Arc2d.centerPoint arc)
        )

module OpenSolid.EllipticalArc2d
    exposing
        ( ArcLengthParameterized
        , EllipticalArc2d
        , SweptAngle
        , arcLength
        , arcLengthFromParameterValue
        , arcLengthParameterized
        , arcLengthToParameterValue
        , axes
        , centerPoint
        , derivative
        , derivativeMagnitude
        , endPoint
        , fromEndpoints
        , largeNegative
        , largePositive
        , maxSecondDerivativeMagnitude
        , mirrorAcross
        , placeIn
        , pointAlong
        , pointOn
        , relativeTo
        , rotateAround
        , scaleAbout
        , smallNegative
        , smallPositive
        , startAngle
        , startPoint
        , sweptAngle
        , tangentAlong
        , translateBy
        , with
        , xAxis
        , xDirection
        , xRadius
        , yAxis
        , yDirection
        , yRadius
        )

import OpenSolid.ArcLength as ArcLength
import OpenSolid.Axis2d as Axis2d exposing (Axis2d)
import OpenSolid.Direction2d as Direction2d exposing (Direction2d)
import OpenSolid.Frame2d as Frame2d exposing (Frame2d)
import OpenSolid.Geometry.Internal as Internal
import OpenSolid.Interval as Interval
import OpenSolid.Point2d as Point2d exposing (Point2d)
import OpenSolid.Scalar as Scalar
import OpenSolid.Vector2d as Vector2d exposing (Vector2d)


type alias EllipticalArc2d =
    Internal.EllipticalArc2d


with : { centerPoint : Point2d, xDirection : Direction2d, xRadius : Float, yRadius : Float, startAngle : Float, sweptAngle : Float } -> EllipticalArc2d
with { centerPoint, xDirection, xRadius, yRadius, startAngle, sweptAngle } =
    Internal.EllipticalArc2d
        { axes =
            Frame2d.with { originPoint = centerPoint, xDirection = xDirection }
        , xRadius = abs xRadius
        , yRadius = abs yRadius
        , startAngle = startAngle
        , sweptAngle = sweptAngle
        }


fromEndpoints : { startPoint : Point2d, endPoint : Point2d, xDirection : Direction2d, xRadius : Float, yRadius : Float, sweptAngle : SweptAngle } -> Maybe EllipticalArc2d
fromEndpoints { startPoint, endPoint, xDirection, xRadius, yRadius, sweptAngle } =
    if xRadius > 0 && yRadius > 0 then
        let
            temporaryFrame =
                Frame2d.with
                    { originPoint =
                        startPoint
                            |> Point2d.translateBy
                                (Vector2d.with
                                    { direction = xDirection
                                    , length = -xRadius
                                    }
                                )
                    , xDirection = xDirection
                    }

            ( x2Ellipse, y2Ellipse ) =
                endPoint
                    |> Point2d.relativeTo temporaryFrame
                    |> Point2d.coordinates

            x2 =
                x2Ellipse / xRadius

            y2 =
                y2Ellipse / yRadius

            cx2 =
                x2 - 1

            cy2 =
                y2

            d =
                sqrt (cx2 * cx2 + cy2 * cy2) / 2
        in
        if d > 0 && d < 1 then
            let
                midAngle =
                    atan2 -cy2 -cx2

                offsetAngle =
                    acos d

                ( startAngle, sweptAngleInRadians ) =
                    case sweptAngle of
                        SmallPositive ->
                            ( midAngle + offsetAngle
                            , pi - 2 * offsetAngle
                            )

                        SmallNegative ->
                            ( midAngle - offsetAngle
                            , -pi + 2 * offsetAngle
                            )

                        LargePositive ->
                            ( midAngle - offsetAngle
                            , pi + 2 * offsetAngle
                            )

                        LargeNegative ->
                            ( midAngle + offsetAngle
                            , -pi - 2 * offsetAngle
                            )

                yDirection =
                    Direction2d.perpendicularTo xDirection

                centerPoint =
                    Point2d.placeIn temporaryFrame <|
                        Point2d.fromCoordinates
                            ( xRadius - xRadius * cos startAngle
                            , -yRadius * sin startAngle
                            )
            in
            Just <|
                with
                    { centerPoint = centerPoint
                    , xDirection = xDirection
                    , xRadius = xRadius
                    , yRadius = yRadius
                    , startAngle =
                        if startAngle > pi then
                            startAngle - 2 * pi
                        else if startAngle < -pi then
                            startAngle + 2 * pi
                        else
                            startAngle
                    , sweptAngle = sweptAngleInRadians
                    }
        else
            Nothing
    else
        Nothing


{-| Argument type used in [`fromEndpoints`](#fromEndpoints).
-}
type SweptAngle
    = SmallPositive
    | SmallNegative
    | LargePositive
    | LargeNegative


{-| Flag used as argument to [`fromEndpoints`](#fromEndpoints).
-}
smallPositive : SweptAngle
smallPositive =
    SmallPositive


{-| Flag used as argument to [`fromEndpoints`](#fromEndpoints).
-}
smallNegative : SweptAngle
smallNegative =
    SmallNegative


{-| Flag used as argument to [`fromEndpoints`](#fromEndpoints).
-}
largePositive : SweptAngle
largePositive =
    LargePositive


{-| Flag used as argument to [`fromEndpoints`](#fromEndpoints).
-}
largeNegative : SweptAngle
largeNegative =
    LargeNegative


centerPoint : EllipticalArc2d -> Point2d
centerPoint arc =
    Frame2d.originPoint (axes arc)


axes : EllipticalArc2d -> Frame2d
axes (Internal.EllipticalArc2d { axes }) =
    axes


xAxis : EllipticalArc2d -> Axis2d
xAxis arc =
    Frame2d.xAxis (axes arc)


yAxis : EllipticalArc2d -> Axis2d
yAxis arc =
    Frame2d.yAxis (axes arc)


xRadius : EllipticalArc2d -> Float
xRadius (Internal.EllipticalArc2d { xRadius }) =
    xRadius


yRadius : EllipticalArc2d -> Float
yRadius (Internal.EllipticalArc2d { yRadius }) =
    yRadius


startAngle : EllipticalArc2d -> Float
startAngle (Internal.EllipticalArc2d { startAngle }) =
    startAngle


sweptAngle : EllipticalArc2d -> Float
sweptAngle (Internal.EllipticalArc2d { sweptAngle }) =
    sweptAngle


pointOn : EllipticalArc2d -> Float -> Point2d
pointOn arc t =
    let
        theta =
            startAngle arc + t * sweptAngle arc
    in
    Point2d.placeIn (axes arc) <|
        Point2d.fromCoordinates
            ( xRadius arc * cos theta
            , yRadius arc * sin theta
            )


derivative : EllipticalArc2d -> Float -> Vector2d
derivative arc t =
    let
        deltaTheta =
            sweptAngle arc

        theta =
            startAngle arc + t * deltaTheta
    in
    Vector2d.placeIn (axes arc) <|
        Vector2d.fromComponents
            ( -(xRadius arc) * deltaTheta * sin theta
            , yRadius arc * deltaTheta * cos theta
            )


startPoint : EllipticalArc2d -> Point2d
startPoint arc =
    pointOn arc 0


endPoint : EllipticalArc2d -> Point2d
endPoint arc =
    pointOn arc 1


xDirection : EllipticalArc2d -> Direction2d
xDirection arc =
    Frame2d.xDirection (axes arc)


yDirection : EllipticalArc2d -> Direction2d
yDirection arc =
    Frame2d.yDirection (axes arc)


scaleAbout : Point2d -> Float -> EllipticalArc2d -> EllipticalArc2d
scaleAbout point scale arc =
    let
        newCenterPoint =
            Point2d.scaleAbout point scale (centerPoint arc)

        newAxes =
            if scale >= 0 then
                Frame2d.unsafe
                    { originPoint = newCenterPoint
                    , xDirection = xDirection arc
                    , yDirection = yDirection arc
                    }
            else
                Frame2d.unsafe
                    { originPoint = newCenterPoint
                    , xDirection = Direction2d.flip (xDirection arc)
                    , yDirection = Direction2d.flip (yDirection arc)
                    }
    in
    Internal.EllipticalArc2d
        { axes = newAxes
        , xRadius = abs (scale * xRadius arc)
        , yRadius = abs (scale * yRadius arc)
        , startAngle = startAngle arc
        , sweptAngle = sweptAngle arc
        }


transformBy : (Frame2d -> Frame2d) -> EllipticalArc2d -> EllipticalArc2d
transformBy axesTransformation (Internal.EllipticalArc2d properties) =
    Internal.EllipticalArc2d
        { properties | axes = axesTransformation properties.axes }


rotateAround : Point2d -> Float -> EllipticalArc2d -> EllipticalArc2d
rotateAround point angle =
    transformBy (Frame2d.rotateAround point angle)


translateBy : Vector2d -> EllipticalArc2d -> EllipticalArc2d
translateBy displacement =
    transformBy (Frame2d.translateBy displacement)


mirrorAcross : Axis2d -> EllipticalArc2d -> EllipticalArc2d
mirrorAcross axis =
    transformBy (Frame2d.mirrorAcross axis)


placeIn : Frame2d -> EllipticalArc2d -> EllipticalArc2d
placeIn frame =
    transformBy (Frame2d.placeIn frame)


relativeTo : Frame2d -> EllipticalArc2d -> EllipticalArc2d
relativeTo frame =
    transformBy (Frame2d.relativeTo frame)


maxSecondDerivativeMagnitude : EllipticalArc2d -> Float
maxSecondDerivativeMagnitude arc =
    let
        theta0 =
            startAngle arc

        dTheta =
            sweptAngle arc

        theta1 =
            theta0 + dTheta

        dThetaSquared =
            dTheta * dTheta

        rx =
            xRadius arc

        ry =
            yRadius arc

        kx =
            dThetaSquared * rx

        ky =
            dThetaSquared * ry

        thetaInterval =
            Scalar.hull theta0 theta1

        sinThetaInterval =
            Interval.sin thetaInterval

        includeKx =
            Interval.contains 0 sinThetaInterval

        includeKy =
            (Interval.maxValue sinThetaInterval == 1)
                || (Interval.minValue sinThetaInterval == -1)
    in
    if (kx >= ky) && includeKx then
        -- kx is the global max and is included in the arc
        kx
    else if (ky >= kx) && includeKy then
        -- ky is the global max and is included in the arc
        ky
    else
        -- global max is not included in the arc, so max must be at an endpoint
        let
            rxSquared =
                rx * rx

            rySquared =
                ry * ry

            cosTheta0 =
                cos theta0

            sinTheta0 =
                sin theta0

            cosTheta1 =
                cos theta1

            sinTheta1 =
                sin theta1

            d0 =
                (rxSquared * cosTheta0 * cosTheta0)
                    + (rySquared * sinTheta0 * sinTheta0)

            d1 =
                (rxSquared * cosTheta1 * cosTheta1)
                    + (rySquared * sinTheta1 * sinTheta1)
        in
        dThetaSquared * sqrt (max d0 d1)


derivativeMagnitude : EllipticalArc2d -> Float -> Float
derivativeMagnitude arc =
    let
        rx =
            xRadius arc

        ry =
            yRadius arc

        theta0 =
            startAngle arc

        dTheta =
            sweptAngle arc

        absDTheta =
            abs dTheta
    in
    \t ->
        let
            theta =
                theta0 + t * dTheta

            dx =
                rx * sin theta

            dy =
                ry * cos theta
        in
        absDTheta * sqrt (dx * dx + dy * dy)


{-| An elliptical arc that has been parameterized by arc length.
-}
type ArcLengthParameterized
    = ArcLengthParameterized EllipticalArc2d ArcLength.Parameterization


{-| Build an arc length parameterization of the given elliptical arc.
-}
arcLengthParameterized : Float -> EllipticalArc2d -> ArcLengthParameterized
arcLengthParameterized tolerance arc =
    let
        parameterization =
            ArcLength.parameterization
                { tolerance = tolerance
                , derivativeMagnitude = derivativeMagnitude arc
                , maxSecondDerivativeMagnitude =
                    maxSecondDerivativeMagnitude arc
                }
    in
    ArcLengthParameterized arc parameterization


{-| Find the total arc length of an elliptical arc. This will be accurate to
within the tolerance given when calling `arcLengthParameterized`.
-}
arcLength : ArcLengthParameterized -> Float
arcLength (ArcLengthParameterized _ parameterization) =
    ArcLength.fromParameterization parameterization


{-| Get the point along an elliptical arc at a given arc length.
-}
pointAlong : ArcLengthParameterized -> Float -> Maybe Point2d
pointAlong (ArcLengthParameterized arc parameterization) s =
    ArcLength.toParameterValue parameterization s |> Maybe.map (pointOn arc)


{-| Get the tangent direction along an elliptical arc at a given arc length.
-}
tangentAlong : ArcLengthParameterized -> Float -> Maybe Direction2d
tangentAlong (ArcLengthParameterized arc parameterization) s =
    ArcLength.toParameterValue parameterization s
        |> Maybe.map (derivative arc)
        |> Maybe.andThen Vector2d.direction


{-| Get the parameter value along an elliptical arc at a given arc length. If
the given arc length is less than zero or greater than the arc length of the
arc, returns `Nothing`.
-}
arcLengthToParameterValue : ArcLengthParameterized -> Float -> Maybe Float
arcLengthToParameterValue (ArcLengthParameterized _ parameterization) s =
    ArcLength.toParameterValue parameterization s


{-| Get the arc length along an elliptical arc at a given parameter value. If
the given parameter value is less than zero or greater than one, returns
`Nothing`.
-}
arcLengthFromParameterValue : ArcLengthParameterized -> Float -> Maybe Float
arcLengthFromParameterValue (ArcLengthParameterized _ parameterization) t =
    ArcLength.fromParameterValue parameterization t

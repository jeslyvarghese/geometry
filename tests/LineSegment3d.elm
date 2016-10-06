{- This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, you can
   obtain one at http://mozilla.org/MPL/2.0/.

   Copyright 2016 by Ian Mackenzie
   ian.e.mackenzie@gmail.com
-}


module LineSegment3d exposing (suite)

import Test exposing (Test)
import Test.Runner.Html as Html
import OpenSolid.LineSegment3d as LineSegment3d
import OpenSolid.Core.Encode as Encode
import OpenSolid.Core.Decode as Decode
import OpenSolid.Core.Fuzz as Fuzz
import OpenSolid.Core.Expect as Expect
import Generic


jsonRoundTrips : Test
jsonRoundTrips =
    Generic.jsonRoundTrips Fuzz.lineSegment3d
        Encode.lineSegment3d
        Decode.lineSegment3d


suite : Test
suite =
    Test.describe "OpenSolid.Core.LineSegment3d"
        [ jsonRoundTrips
        ]


main : Program Never
main =
    Html.run suite
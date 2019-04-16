import Dependencies._

lazy val root = (project in file(".")).
  settings(
    inThisBuild(List(
      organization := "org.rwtodd",
      scalaVersion := "2.12.8",
      version      := "1.0"
    )),
    name := "postcard",
    scalacOptions ++= Seq(
       "-encoding", "utf8", // Option and arguments on same line
       "-opt:l:method",
       "-opt:l:inline",
       "-opt-inline-from","org.rwtodd.postcard.V3"
    ),
    initialCommands in console := "import org.rwtodd.postcard._",
    // libraryDependencies += argparse
  )

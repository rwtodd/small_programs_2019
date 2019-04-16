package org.rwtodd.postcard

final case class V3(val x:Float, val y:Float, val z:Float) {
  @inline def this(v:Float) = this(v,v,v)

  @inline def +(b: V3) = V3(x+b.x,y+b.y,z+b.z)
  @inline def +(b: Float) = V3(x+b,y+b,z+b)
  @inline def *(b: V3) = V3(x*b.x,y*b.y,z*b.z)
  @inline def *(b: Float) = V3(x*b,y*b,z*b)
  @inline def dot(b: V3) : Float = x*b.x + y*b.y + z*b.z
  @inline def norm : V3 = this * (1.0f/Math.sqrt(this dot this).toFloat)
  @inline def minPart : Float = Math.min(Math.min(x,y),z)
}

final case class HtDist(val hitType: Symbol, val dist: Float)

object Main {
  def time[R](block: => R): R = {
      val t0 = System.nanoTime()
      val result = block    // call-by-name
      val t1 = System.nanoTime()
      println(f"Elapsed time: ${(t1 - t0)/1000000000.0}%8.2f s")
      result
  }

  def boxTest(pos: V3, lowleft: V3, upright: V3): Float = {
    val ll = (pos + lowleft * -1).minPart
    val ur = (upright + pos * -1).minPart
    -Math.min(ll, ur)
  }

  private[this] val queryBeginE : Array[(V3,V3)] =
     "5O5_5W9W5_9_AOEOCOC_A_E_IOQ_I_QOUOY_Y_]OWW[WaOa_aWeWa_e_cWiO".
       grouped(4).
       map { grp => 
         val begin = V3(grp(0).toInt - 79, grp(1).toInt - 79, 0) * 0.5f
         val e = V3(grp(2).toInt - 79, grp(3).toInt - 79, 0) * 0.5f + begin * -1f
         (begin, e)
       }.toArray

  private[this] val curves = Array( V3(-11,6,0) * -1 , V3(11, 6, 0) * -1 )

  // returns (hitType, dist)
  def queryDatabase(position: V3) : HtDist = {
     var dist = 1e9f
     val f = position.copy(z = 0)
     var idx = 0
     while (idx < 15) {
        val (begin, e) = queryBeginE(idx)
        val o = f + (begin + 
                     e * 
                     Math.min( 
                        -Math.min(((begin + f * -1) dot e) / (e dot e), 0f),
                        1f)) * -1.0f
        dist = Math.min(dist, o dot o)
        idx = idx + 1
     }
     dist = Math.sqrt(dist).toFloat

     idx = 0
     while (idx < 2)  {
        val o = f + curves(idx)
        dist = Math.min(dist,
                        (if (o.x > 0) Math.abs(Math.sqrt(o dot o) - 2)
                        else { 
                           val o2 = o.copy(y = o.y + 
                                               (if (o.y > 0) -2 else 2))
                           Math.sqrt(o2 dot o2)
                        }).toFloat)
        idx = idx + 1
     }
     dist = (Math.pow(Math.pow(dist, 8) + 
                      Math.pow(position.z, 8), 0.125) - .5).toFloat
     var hitType = 'Letter

     val roomDist = Math.min(
                      -Math.min(boxTest(position, V3(-30,-0.5f,-30), V3(30,18,30)),
                                boxTest(position, V3(-25,17,-25), V3(25,20,25))),
                      boxTest(
                        position.copy(x = Math.abs(position.x) % 8.0f),
                        V3(1.5f,18.5f,-25),
                        V3(6.5f,20,25)))

     if (roomDist < dist) {
          dist = roomDist
          hitType = 'Wall
     }

     val sun = 19.9f - position.y
     if (sun < dist) {
          dist = sun
          hitType = 'Sun
     }
     
     HtDist(hitType, dist)
  }

  // returns (hitType, hitPos, hitNorm)
  def rayMarching(origin: V3, direction: V3) : (Symbol, V3, V3) = {
    var hitPos : V3 = null
    var hitType = 'None
    var noHitCount = 0
    var total_d = 0.0f
    while(total_d < 100.0f) {
       hitPos = origin + direction * total_d       
       val HtDist(ht, d) = queryDatabase(hitPos)
       hitType = ht
       total_d += d
       noHitCount += 1
       if ((d < 0.01f) || (noHitCount > 99))
         return (hitType, 
                 hitPos,
                 V3(queryDatabase(hitPos + V3(0.01f, 0, 0)).dist - d,
                    queryDatabase(hitPos + V3(0, 0.01f, 0)).dist - d,
                    queryDatabase(hitPos + V3(0, 0, 0.01f)).dist - d).norm)
    }
    return ( 'None, null, null )
  }

  private[this] val lightDirection = V3(0.6f, 0.6f, 1.0f).norm

  def trace(origin: V3, direction: V3) : V3 = {
    var dir = direction
    var orig = origin
    var attenuation = new V3(1.0f)
    var color = new V3(0.0f)

    for( bounceCount <- 1 to 3 ) {
      val (hitType, samplePosition, normal) = rayMarching(orig, dir)
      hitType match {
        case 'None => return color
        case 'Sun => return color + attenuation * V3(50,80,100)
        case 'Letter => {
            dir = dir + normal * ((normal dot dir) * -2.0f) //precedence?
            orig = samplePosition + dir * 0.1f
            attenuation = attenuation * 0.2f
        } 
        case 'Wall => {
            val incidence = normal dot lightDirection
            val p = 6.283185 * Math.random()
            val c = Math.random()
            val s = Math.sqrt(1.0 - c).toFloat
            val g = if (normal.z < 0) -1.0f else 1.0f
            val u = -1.0f / (g + normal.z)
            val v = normal.x * normal.y * u
            dir = V3(v,
                     g + normal.y * normal.y * u,
                     -normal.y) * (Math.cos(p).toFloat * s) +
                  V3(1.0f + g * normal.x * normal.x  * u,
                     g * v,
                     -g * normal.x) * (Math.sin(p).toFloat * s) + normal * Math.sqrt(c).toFloat
            orig = samplePosition + dir * 0.1f
            attenuation = attenuation * 0.2f
            if ((incidence > 0) && 
                (rayMarching(samplePosition + normal * 0.1f, lightDirection)._1 == 'Sun))
               color = color + attenuation * V3(500,400,100) * incidence
        }
      }
    }
    return color
  }

  def image(w: Int, h: Int, samps: Int)(os: java.io.OutputStream): Unit = {
     val position = V3(-22,5,25)
     val goal = (V3(-3,4,0) + position * -1.0f).norm
     val left = V3(goal.z, 0, -goal.x).norm * (1.0f/w)
     val up = V3(goal.y * left.z - goal.z * left.y,
                 goal.z * left.x - goal.x * left.z,
                 goal.x * left.y - goal.y * left.x)
     
     os.write(s"P6 $w $h 255 ".getBytes) 
     for { y <- h.to(1,-1)
           x <- w.to(1,-1) } {
        var color = new V3(0.0f)
        for (p <- 1 to samps) {
           color = color + trace(position,
                                 (goal + left * (x - w/2.0 + Math.random()).toFloat +
                                         up * (y - h/2.0 + Math.random()).toFloat).norm)
        }
        color = color * (1.0f / samps) + (14.0f/241.0f)
        val o = color + 1.0f
        color = V3(color.x/o.x, color.y/o.y, color.z/o.z) * 255f
        os.write(color.x.toInt)
        os.write(color.y.toInt)
        os.write(color.z.toInt)
     }
  }

  def imageToFile(w: Int, h: Int, samps: Int, fn: String): Unit = {
     import java.nio.file.{Paths,Files,StandardOpenOption}
     val bo = new java.io.BufferedOutputStream(
                     Files.newOutputStream(Paths.get(fn), 
                                           StandardOpenOption.CREATE,
                                           StandardOpenOption.TRUNCATE_EXISTING,
                                           StandardOpenOption.WRITE))
     image(w,h,samps)(bo)
     bo.close()
  }
}
